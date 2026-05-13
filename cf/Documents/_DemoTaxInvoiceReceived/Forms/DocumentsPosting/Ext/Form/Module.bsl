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
	
	Counterparty = ?(Parameters.CheckKind.Property2 <> Undefined, Parameters.CheckKind.Property2, 
		Catalogs._DemoCounterparties.EmptyRef());
	If Not Counterparty.IsEmpty() Then
		TitleClarification = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'контрагента %1';
				|en = 'counterparty %1';"), Counterparty);
	Else
		TitleClarification = NStr("ru = 'всех контрагентов';
									|en = 'all counterparties';");
	EndIf;
	Items.Explanation.Title = StringFunctionsClientServer.SubstituteParametersToString(Items.Explanation.Title,
		TitleClarification);
	
	SetCurrentPage(ThisObject, False, False, False);
	
	If Common.IsMobileClient() Then
		CommandBarLocation = FormCommandBarLabelLocation.Auto;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure PostReceivedTaxInvoice(Command)
	
	TimeConsumingOperation = PostTaxInvoicesInBackground();
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow = False;
	
	CallbackOnCompletion = New NotifyDescription("PostTaxInvoicesInBackgroundCompletion", ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	
EndProcedure

&AtClient
Procedure TaxInvoicesList(Command)
	
	OpenForm("Document._DemoTaxInvoiceReceived.ListForm");
	
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure SetCurrentPage(Form, TroubleshootingInProgress, FixedSuccessfully, ErrorInCorrectionAlgorithm)
	
	FormItems = Form.Items;
	If TroubleshootingInProgress Then
		FormItems.TroubleshootingIndicatorGroup.Visible           = True;
		FormItems.TroubleshootingStartIndicatorGroup.Visible     = False;
		FormItems.TroubleshootingSuccessIndicatorGroup.Visible   = False;
		FormItems.TroubleshootingFailedIndicatorGroup.Visible = False;
	ElsIf FixedSuccessfully Then
		FormItems.TroubleshootingIndicatorGroup.Visible           = False;
		FormItems.TroubleshootingStartIndicatorGroup.Visible     = False;
		FormItems.TroubleshootingSuccessIndicatorGroup.Visible   = True;
		FormItems.Post.Visible                             = False;
		FormItems.TroubleshootingFailedIndicatorGroup.Visible = False;
	ElsIf ErrorInCorrectionAlgorithm Then
		FormItems.TroubleshootingIndicatorGroup.Visible           = False;
		FormItems.TroubleshootingStartIndicatorGroup.Visible     = False;
		FormItems.TroubleshootingSuccessIndicatorGroup.Visible   = False;
		FormItems.TroubleshootingFailedIndicatorGroup.Visible = True;
	Else
		FormItems.TroubleshootingIndicatorGroup.Visible         = False;
		FormItems.TroubleshootingStartIndicatorGroup.Visible   = True;
		FormItems.TroubleshootingSuccessIndicatorGroup.Visible = False;
	EndIf;
	
EndProcedure

&AtServer
Function PostTaxInvoicesInBackground()
	
	If TimeConsumingOperation <> Undefined Then
		TimeConsumingOperations.CancelJobExecution(TimeConsumingOperation.JobID);
	EndIf;
	
	SetCurrentPage(ThisObject, True, False, False);
	
	If Counterparty.IsEmpty() Then
		BackgroundJobDescription = NStr("ru = 'Проведение счет-фактур всех контрагентов';
											|en = 'Post tax invoices of all counterparties';");
	Else
		BackgroundJobDescription = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Проведение счет-фактур контрагента ""%1""';
				|en = 'Post tax invoices of counterparty %1';"), Counterparty);
	EndIf;
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = BackgroundJobDescription;
	
	CheckParameters = New Structure("CheckKind", Parameters.CheckKind);
	
	Return TimeConsumingOperations.ExecuteInBackground("Documents._DemoTaxInvoiceReceived.PostTaxInvoicesForTroublesomeCounterparties",
		CheckParameters, ExecutionParameters);
		
EndFunction

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AdditionalParameters - Undefined
//
&AtClient
Procedure PostTaxInvoicesInBackgroundCompletion(Result, AdditionalParameters) Export
	
	TimeConsumingOperation = Undefined;

	If Result = Undefined Then
		SetCurrentPage(ThisObject, True, False, False);
		Return;
	ElsIf Result.Status = "Error" Then
		SetCurrentPage(ThisObject, False, False, False);
		StandardSubsystemsClient.OutputErrorInfo(
			Result.ErrorInfo);
	ElsIf Result.Status = "Completed2" Then
		ProcessSuccessfulCorrectionCompletion(Result);
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessSuccessfulCorrectionCompletion(Result)
	
	ResultAddress      = Result.ResultAddress;
	PostingResults = GetFromTempStorage(ResultAddress);
	
	NumberOfUnverified          = PostingResults.NumberOfUnverified;
	PostedCount            = PostingResults.PostedCount;
	CountOfIncorrectlyFilledDocuments = PostingResults.CountOfIncorrectlyFilledDocuments;
	
	If NumberOfUnverified = 0 And CountOfIncorrectlyFilledDocuments = 0 Then
		SetCurrentPage(ThisObject, False, True, False);
		Items.TroubleshootingSuccessLabel.Title = SuccessDetails(PostedCount);
	Else
		SetCurrentPage(ThisObject, False, False, True);
		Items.TroubleshootingFailedLabel.Title = FailureReasonsDetails(ResultAddress, PostedCount, NumberOfUnverified, CountOfIncorrectlyFilledDocuments);
	EndIf;
	
EndProcedure

&AtServerNoContext
Function FailureReasonsDetails(ResultAddress, PostedCount, NumberOfUnverified, CountOfIncorrectlyFilledDocuments)
	
	Information = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Проведено: %1
	|Не проведено: %2
	|в т.ч. из-за незаполненных данных: %3';
	|en = 'Posted: %1
	|Not posted:%2
	|including because of unfilled data: %3';"),
	Format(PostedCount, "NZ=0; NG=0"), Format(NumberOfUnverified, "NZ=0; NG=0"), Format(CountOfIncorrectlyFilledDocuments, "NZ=0; NG=0"));
	
	ReportHyperlink = New FormattedString(NStr("ru = 'Подробнее...';
														|en = 'Details…';"), , , , ResultAddress);
	
	Return New FormattedString(Information, Chars.LF, ReportHyperlink);
	
EndFunction

&AtServerNoContext
Function SuccessDetails(PostedCount)
	
	TextInformationOnPostedItems = StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Успешно проведено документов: %1';
																									|en = 'Successfully posted documents: %1';"),
		Format(PostedCount, "NZ=0; NG=0"));
	
	Return New FormattedString(TextInformationOnPostedItems, , StyleColors.SuccessResultColor);
	
EndFunction

&AtClient
Procedure TroubleshootingFailedLabelURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	TaxInvoicesWithIssuesList = TaxInvoicesWithIssuesList(FormattedStringURL);
	TaxInvoicesWithIssuesList.Show(NStr("ru = 'Список проблемных счетов-фактур';
												|en = 'List of tax invoices with issues';"), , True);
	
EndProcedure

&AtServer
Function TaxInvoicesWithIssuesList(FormattedStringURL)
	
	PostingResults           = GetFromTempStorage(FormattedStringURL);
	IssuesDetailedInformation = PostingResults.IssuesDetailedInformation;
	
	TaxInvoicesWithIssuesList = New SpreadsheetDocument;
	Template                        = Documents._DemoTaxInvoiceReceived.GetTemplate("Template");
	
	SectionHeader = Template.GetArea("Header");
	TaxInvoicesWithIssuesList.Put(SectionHeader);
	
	For Each InformationItem In IssuesDetailedInformation Do
		
		AreaRow = Template.GetArea("String");
		
		AreaRow.Parameters.DocumentReference = InformationItem.Key;
		AreaRow.Parameters.ExceptionText  = InformationItem.Value;
		
		TaxInvoicesWithIssuesList.Put(AreaRow);
		
	EndDo;
	
	TaxInvoicesWithIssuesList.FixedTop = 1;
	TaxInvoicesWithIssuesList.Protection         = True;
	
	Return TaxInvoicesWithIssuesList;
	
EndFunction

#EndRegion