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

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Seller.Partner)";
	
EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region Private

// Posts unposted documents _DemoTaxInvoiceReceived. Called by the handler that fixes posting issues. 
// The documents are found by the check See _DemoStandardSubsystemsClient.PostTaxInvoicesForTroublesomeCounterparties.
// _DemoStandardSubsystems.CheckReceivedTaxInvoicePosting.
//
// Parameters:
//    CheckParameters - Structure:
//        * CheckKind - CatalogRef.ChecksKinds - Kind of the running check.
//    StorageAddress - String - Temporary storage address for the return value.
//
Procedure PostTaxInvoicesForTroublesomeCounterparties(Val CheckParameters, StorageAddress = Undefined) Export
	
	CheckKind = CheckParameters.CheckKind;
	
	BeginTransaction();
	Try
		
		CheckRule = AccountingAudit.CheckByID("Demo.CheckReceivedTaxInvoicePosting");
		
		DataLock = New DataLock;
		LockItem = DataLock.Add("InformationRegister.AccountingCheckResults");
		LockItem.SetValue("CheckRule", CheckRule);
		LockItem.SetValue("CheckKind", CheckKind);
		LockItem.SetValue("IgnoreIssue", False);
		LockItem.Mode = DataLockMode.Shared;
		
		CheckKindLockItem = DataLock.Add("Catalog.ChecksKinds");
		CheckKindLockItem.SetValue("Ref", CheckKind);
		CheckKindLockItem.Mode = DataLockMode.Shared;
		
		DataLock.Lock();
		
		Query = New Query(
		"SELECT TOP 1000
		|	AccountingCheckResults.ObjectWithIssue AS ObjectWithIssue
		|FROM
		|	InformationRegister.AccountingCheckResults AS AccountingCheckResults
		|WHERE
		|	AccountingCheckResults.CheckRule = &CheckRule
		|	AND NOT AccountingCheckResults.IgnoreIssue
		|	AND AccountingCheckResults.ObjectWithIssue > &ObjectWithIssue
		|	AND &ConditionByCounterparty
		|
		|ORDER BY
		|	AccountingCheckResults.ObjectWithIssue");
		
		Query.SetParameter("CheckRule",  CheckRule);
		Query.SetParameter("ObjectWithIssue", "");
		
		Counterparty = Common.ObjectAttributeValue(CheckKind, "Property2");
		If Counterparty = Undefined Or Not ValueIsFilled(Counterparty) Then
			Query.Text = StrReplace(Query.Text, "&ConditionByCounterparty", "True");
		Else
			Query.Text = StrReplace(Query.Text, "&ConditionByCounterparty",
				"CAST(AccountingCheckResults.CheckKind.Property2 AS Catalog._DemoCounterparties) = &Counterparty");
			Query.SetParameter("Counterparty", Counterparty);
		EndIf;
		
		Result = Query.Execute().Unload();
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		WriteLogEvent(NStr("ru = 'Исправление счетов фактур';
										|en = 'Tax invoice correction';", Common.DefaultLanguageCode()), 
			EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
		Raise;
		
	EndTry;
	
	IssuesDetailedInformation = New Map;
	
	PostedCount            = 0;
	NumberOfUnverified          = 0;
	CountOfIncorrectlyFilledDocuments = 0;
	
	While Result.Count() > 0 Do
		
		For Each ResultString1 In Result Do
			
			DocumentRef = ResultString1.ObjectWithIssue;
			BeginTransaction();
			
			Try
				
				DataLock = New DataLock;
				LockItem = DataLock.Add("Document._DemoTaxInvoiceReceived");
				LockItem.SetValue("Ref", DocumentRef);
				DataLock.Lock();
				
				DocumentObject = DocumentRef.GetObject();
				
				If DocumentObject = Undefined Or DocumentObject.Posted Then
					RollbackTransaction();
					Continue;
				EndIf;
				
				If Not DocumentObject.CheckFilling() Then
					
					RollbackTransaction();
					IssuesDetailedInformation.Insert(DocumentRef, ObjectFillingErrors());
					CountOfIncorrectlyFilledDocuments = CountOfIncorrectlyFilledDocuments + 1;
					
					Continue;
					
				EndIf;
				
				DocumentObject.Write(DocumentWriteMode.Posting);
				PostedCount = PostedCount + 1;
				CommitTransaction();
				
			Except
				
				RollbackTransaction();
				IssuesDetailedInformation.Insert(DocumentRef, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
				NumberOfUnverified = NumberOfUnverified + 1;
				
			EndTry;
			
		EndDo;
		
		Query.SetParameter("ObjectWithIssue", DocumentRef);
		Result = Query.Execute().Unload(); // @skip-check query-in-loop - Batch-wise document posting.
		
	EndDo;
	
	FinalResult = New Structure;
	FinalResult.Insert("PostedCount",            PostedCount);
	FinalResult.Insert("NumberOfUnverified",          NumberOfUnverified);
	FinalResult.Insert("CountOfIncorrectlyFilledDocuments", CountOfIncorrectlyFilledDocuments);
	FinalResult.Insert("IssuesDetailedInformation",   IssuesDetailedInformation);
	
	PutToTempStorage(FinalResult, StorageAddress);
	
EndProcedure

Function ObjectFillingErrors()
	
	IssueSummary = "";
	For Each UserMessage1 In GetUserMessages(True) Do
		IssueSummary = IssueSummary + ?(ValueIsFilled(IssueSummary), Chars.LF, "") + UserMessage1.Text;
	EndDo;
	
	Return ?(IsBlankString(IssueSummary), NStr("ru = 'Для подробной информации откройте форму объекта.';
													|en = 'For more information, open the object form.';"), IssueSummary);
	
EndFunction

#EndRegion
	
#EndIf
