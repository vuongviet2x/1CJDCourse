///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Public

#Region ForCallsFromOtherSubsystems

#Region Core

// See CommonOverridable.OnAddClientParametersOnStart
Procedure OnAddClientParametersOnStart(Parameters) Export
	
	If Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	SuggestOpenWebSiteOnStart = Common.CommonSettingsStorageLoad(
		"UserCommonSettings", 
		"SuggestOpenWebSiteOnStart",
		False);
	Parameters.Insert("SuggestOpenWebSiteOnStart", SuggestOpenWebSiteOnStart);
	Parameters.Insert("ConfigurationWebsiteAddress", Metadata.ConfigurationInformationAddress);
	If Not Users.IsExternalUserSession() Then
		Parameters.Insert("CurrentProject", SessionParameters._DemoCurrentProject);
	EndIf;
	
EndProcedure

// See CommonOverridable.OnAddClientParameters
Procedure OnAddClientParameters(Parameters) Export

	If Not Users.IsExternalUserSession() Then
		Parameters.Insert("CurrentProject", SessionParameters._DemoCurrentProject);
	EndIf;

EndProcedure

// See CommonOverridable.OnAddMetadataObjectsRenaming.
Procedure OnAddMetadataObjectsRenaming(Total) Export
	
	// 3.0.1.21
	Common.AddRenaming(Total, "3.0.1.21",
		"Role._DemoBasicUserAccessSSL", "Role._DemoBasicAccessSSL");
	
EndProcedure

// See CommonOverridable.OnDetermineCommonCoreParameters.
Procedure OnDetermineCommonCoreParameters(CommonParameters) Export
	
	CommonParameters.PersonalSettingsFormName = "CommonForm._DemoMySettings";
	
EndProcedure

// See CommonOverridable.OnDetermineDisabledSubsystems.
Procedure OnDetermineDisabledSubsystems(DisabledSubsystems) Export
	
	DisabledSubsystems = Common.CommonSettingsStorageLoad(
		"Core", "DisabledSubsystems", New Map);
	
EndProcedure

#EndRegion

#Region BusinessProcessesAndTasks

// See BusinessProcessesAndTasksOverridable.OnFillingAccessValuesSets.
Procedure OnFillBusinessProcessesAccessValuesSets(Object, Table) Export
	
	If TypeOf(Object) = Type("BusinessProcessObject.Job") Then
		// The access rights
		// - Read: Author OR Performer (addressing-wise) OR Supervisor (addressing-wise).
		// - Update: Author.
		
		// If the subject is not specified (the business process is not based on another subject),
		// it is not involved in the restriction logic.
		
		// Read, Update: Set #1.
		String = Table.Add();
		String.SetNumber     = 1;
		String.Read          = True;
		String.Update       = True;
		String.AccessValue = Object.Author;
		
		// Read: Set #2.
		String = Table.Add();
		String.SetNumber     = 2;
		String.Read          = True;
		String.AccessValue = Object.TaskPerformersGroup;
		
		// Read: Set #3.
		String = Table.Add();
		String.SetNumber     = 3;
		String.Read          = True;
		String.AccessValue = Object.TaskPerformersGroupSupervisor;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Interactions

// See InteractionsOverridable.OnFillingAccessValuesSets.
Procedure OnFillAccessValuesSetsForInteractionObject(Object, Table) Export
	
	If TypeOf(Object) = Type("DocumentObject.Meeting") Then
		OnFillAccessValuesSetsForMeeting(Object, Table);
		
	ElsIf TypeOf(Object) = Type("DocumentObject.PlannedInteraction") Then
		OnFillAccessValuesSetsForScheduledInteraction(Object, Table);
		
	ElsIf TypeOf(Object) = Type("DocumentObject.SMSMessage") Then
		OnFillAccessValuesSetsForSMSMessage(Object, Table);
		
	ElsIf TypeOf(Object) = Type("DocumentObject.PhoneCall") Then
		OnFillAccessValuesSetsForPhoneCall(Object, Table);
		
	ElsIf TypeOf(Object) = Type("DocumentObject.IncomingEmail") Then
		OnFillAccessValuesSetsForIncomingEmail(Object, Table);
		
	ElsIf TypeOf(Object) = Type("DocumentObject.OutgoingEmail") Then
		OnFillAccessValuesSetsForOutgoingEmail(Object, Table);
	EndIf;
	
EndProcedure

#EndRegion

#Region PeriodClosingDates

// See PeriodClosingDatesOverridable.InterfaceSetup.
Procedure InterfaceSetup(InterfaceSettings5) Export
	
	InterfaceSettings5.UseExternalUsers = True;
	
EndProcedure

// See PeriodClosingDatesOverridable.OnFillPeriodClosingDatesSections.
Procedure OnFillPeriodClosingDatesSections(Sections) Export
	
	Section = Sections.Add();
	Section.Name  = "_DemoBank";
	Section.Id = New UUID("4109a54a-f3ea-474c-9079-be08bf335668");
	Section.Presentation = NStr("ru = 'Демо: Банк';
								|en = 'Demo: Bank';");
	Section.ObjectsTypes.Add(Type("CatalogRef._DemoBankAccounts"));

	Section = Sections.Add();
	Section.Name  = "_DemoPayrollAccrual";
	Section.Id = New UUID("100aba96-ea50-4f82-a06c-2e3fdc39a9f1");
	Section.Presentation = NStr("ru = 'Демо: Начисление зарплаты';
								|en = 'Demo: Earning';");

	Section = Sections.Add();
	Section.Name  = "_DemoWarehouseAccounting";
	Section.Id = New UUID("dc05fcce-97da-4f78-8317-d9b2b7f1388d");
	Section.Presentation = NStr("ru = 'Демо: Складской учет';
								|en = 'Demo: Inventory accounting';");
	Section.ObjectsTypes.Add(Type("CatalogRef._DemoStorageLocations"));

	Section = Sections.Add();
	Section.Name  = "_DemoTrade";
	Section.Id = New UUID("7d63fbe5-db98-407e-89f5-c770e6a90cb2");
	Section.Presentation = NStr("ru = 'Демо: Торговля';
								|en = 'Demo: Trade industry';");
	Section.ObjectsTypes.Add(Type("EnumRef._DemoBusinessEntityIndividual"));
	
EndProcedure

// See PeriodClosingDatesOverridable.FillDataSourcesForPeriodClosingCheck.
Procedure FillDataSourcesForPeriodClosingCheck(DataSources) Export
	
	PeriodClosingDates.AddRow(DataSources,
		Metadata.Documents._DemoSalesOrder.FullName(),
		"Date", "_DemoTrade", "Partner.PartnerKind");
	
	PeriodClosingDates.AddRow(DataSources,
		Metadata.Documents._DemoSalesOrder.FullName(),
		"Date", "_DemoTrade", "PartnersAndContactPersons.Partner.PartnerKind");
	
	PeriodClosingDates.AddRow(DataSources,
		Metadata.Documents._DemoSalesOrder.FullName(),
		"ProformaInvoices.Account.Date", "_DemoTrade", "Partner.PartnerKind");
	
	PeriodClosingDates.AddRow(DataSources,
		Metadata.Documents._DemoSalesOrder.FullName(),
		"ProformaInvoices.Account.Date", "_DemoTrade", "PartnersAndContactPersons.Partner.PartnerKind");
	
	PeriodClosingDates.AddRow(DataSources,
		Metadata.Documents._DemoSalesOrder.FullName(),
		"ProformaInvoices.Account.Date", "_DemoTrade", "ProformaInvoices.Account.Partner.PartnerKind");
	
	PeriodClosingDates.AddRow(DataSources,
		Metadata.Documents._DemoPayrollAccrual.FullName(),
		"Date", "_DemoPayrollAccrual", "");
	
	PeriodClosingDates.AddRow(DataSources,
		Metadata.Documents._DemoReceivedGoodsRecording.FullName(),
		"Date", "_DemoWarehouseAccounting", "StorageLocation");
	
	PeriodClosingDates.AddRow(DataSources,
		Metadata.Documents._DemoInventoryTransfer.FullName(),
		"Date", "_DemoWarehouseAccounting", "StorageSource");
	
	PeriodClosingDates.AddRow(DataSources,
		Metadata.Documents._DemoInventoryTransfer.FullName(),
		"Date", "_DemoWarehouseAccounting", "StorageLocationDestination");
	
	PeriodClosingDates.AddRow(DataSources,
		Metadata.Documents._DemoGoodsWriteOff.FullName(),
		"Date", "_DemoWarehouseAccounting", "StorageLocation");
	
	PeriodClosingDates.AddRow(DataSources,
		Metadata.Documents._DemoGoodsReceipt.FullName(),
		"Date", "_DemoTrade", "Counterparty.Partner.PartnerKind");
	
	PeriodClosingDates.AddRow(DataSources,
		Metadata.Documents._DemoGoodsReceipt.FullName(),
		"Date", "_DemoWarehouseAccounting", "StorageLocation");
	
	PeriodClosingDates.AddRow(DataSources,
		Metadata.Documents._DemoGoodsSales.FullName(),
		"Date", "_DemoTrade", "Counterparty.Partner.PartnerKind");
		
	PeriodClosingDates.AddRow(DataSources,
		Metadata.Documents._DemoGoodsSales.FullName(),
		"Date", "_DemoWarehouseAccounting", "StorageLocation");
	
	PeriodClosingDates.AddRow(DataSources,
		Metadata.Documents._DemoDebitingFromAccount.FullName(),
		"BankPostingDate", "_DemoBank", "BankAccount");
		
	PeriodClosingDates.AddRow(DataSources,
		Metadata.Documents._DemoStockAdjustmentInStorageLocations.FullName(),
		"Date", "", "");

	
	PeriodClosingDates.AddRow(DataSources,
		Metadata.InformationRegisters._DemoStorageLocationsManagers.FullName(),
		"Period", "_DemoWarehouseAccounting", "StorageLocation");
	
	PeriodClosingDates.AddRow(DataSources,
		Metadata.InformationRegisters.ExchangeRates.FullName(),
		"Period", "", "");
		
	PeriodClosingDates.AddRow(DataSources,
		Metadata.AccumulationRegisters._DemoGoodsBalancesInStorageLocations.FullName(),
		"Period", "_DemoWarehouseAccounting", "StorageLocation");

	
EndProcedure

// See PeriodClosingDatesOverridable.BeforeCheckPeriodClosing.
Procedure BeforeCheckPeriodClosing(Object, PeriodClosingCheck, ImportRestrictionCheckNode, ObjectVersion) Export
	
	If TypeOf(Object) = Type("DocumentObject._DemoSalesOrder") Then
		If Object.IsNew() Then
			OrderClosedOldVersion = False;
		Else
			OrderStatus = Common.ObjectAttributeValue(Object.Ref, "OrderStatus");
			OrderClosedOldVersion = (OrderStatus = Enums._DemoCustomerOrderStatuses.Closed);
		EndIf;
		OrderClosedNewVersion = (Object.OrderStatus = Enums._DemoCustomerOrderStatuses.Closed);
		
		If Not OrderClosedOldVersion And Not OrderClosedNewVersion Then
			PeriodClosingCheck = False;
			ImportRestrictionCheckNode = Undefined;
			
		ElsIf Not OrderClosedNewVersion Then
			ObjectVersion = "OldVersion"; // Check the old object version only.
		
		ElsIf Not OrderClosedOldVersion Then
			ObjectVersion = "NewVersion"; // Check the new object version only.
		EndIf;
		
	ElsIf TypeOf(Object) = Type("DocumentObject._DemoDebitingFromAccount") Then
		// Do not run the check, considering that "BankPostingDate" is specified only
		// after the bank posts the document.
		If Object.IsNew() Then
			ProcessedByBankOldVersion = False;
		Else
			ProcessedByBank = Common.ObjectAttributeValue(Object.Ref, "ProcessedByBank");
			ProcessedByBankOldVersion = ?(TypeOf(ProcessedByBank) <> Type("Boolean"), False, ProcessedByBank);
		EndIf;
		ProcessedByBankNewVersion = Object.ProcessedByBank;
		
		If Not ProcessedByBankNewVersion And Not ProcessedByBankOldVersion Then
			PeriodClosingCheck = False;
			ImportRestrictionCheckNode = Undefined;
			
		ElsIf Not ProcessedByBankNewVersion Then
			ObjectVersion = "OldVersion"; // Check the old object version only.
		
		ElsIf Not ProcessedByBankOldVersion Then
			ObjectVersion = "NewVersion"; // Check the new object version only.
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region ObjectAttributesLock

// See ObjectAttributesLockOverridable.OnDefineObjectsWithLockedAttributes.
Procedure OnDefineObjectsWithLockedAttributes(Objects) Export
	
	Objects.Insert(Metadata.Catalogs._DemoCashRegisters.FullName(), "");
	Objects.Insert(Metadata.Catalogs._DemoProducts.FullName(), "");
	Objects.Insert(Metadata.Documents._DemoSalesOrder.FullName(), "");
	Objects.Insert(Metadata.ChartsOfAccounts._DemoMain.FullName(), "");
	
EndProcedure

#EndRegion


#Region ODataInterface

// See ODataInterfaceOverridable.OnPopulateDependantTablesForODataImportExport
Procedure OnPopulateDependantTablesForODataImportExport(Tables) Export
	
	Tables.Add(Metadata.InformationRegisters.SynchronizedObjectPublicIDs.FullName());
	Tables.Add(Metadata.InformationRegisters.DataExchangeResults.FullName());
	Tables.Add(Metadata.InformationRegisters.InfobaseObjectsMaps.FullName());
	Tables.Add(Metadata.InformationRegisters.DeleteDataExchangeResults.FullName());
	
EndProcedure

#EndRegion

#Region InformationOnStart

// Checks whether ads should be shown at startup.
// 
// Returns:
//  Boolean - "True" if ads should be shown.
//
Function ShouldOpenAdditionalWindowsOnStartup() Export
	
	If Not AccessRight("Read", Metadata.Catalogs._DemoCompanies) Then
		Return False;
	EndIf;
	
	Query = New Query();
	Query.Text =
		"SELECT ALLOWED TOP 1
		|	Companies.Ref
		|FROM
		|	Catalog._DemoCompanies AS Companies";
	
	If Not Query.Execute().IsEmpty() Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

#EndRegion

#Region AccountingAudit

// See AccountingAuditOverridable.OnDefineChecks.
Procedure OnDefineChecks(ChecksGroups, Checks) Export
	
	ChecksGroup = ChecksGroups.Add();
	ChecksGroup.Description                 = NStr("ru = 'Демонстрационные проверки';
														|en = 'Demo checks';");
	ChecksGroup.Id                = "_DemoAccountingChecks";
	ChecksGroup.AccountingChecksContext = "_DemoAccountingChecks";
	
	Validation = Checks.Add();
	Validation.GroupID          = ChecksGroup.Id;
	Validation.Description                 = NStr("ru = 'Проверка заполнения комментария в документах ""Демо: Поступление товаров""';
												|en = 'Check for filled comments in documents ""Demo: Goods receipt""';");
	Validation.Reasons                      = NStr("ru = 'Не введен комментарий в документе.';
												|en = 'A comment is not entered in the document.';");
	Validation.Recommendation                 = NStr("ru = 'Ввести комментарий в документе.';
												|en = 'Enter comment in the document.';");
	Validation.Id                = "Demo.CheckCommentInGoodsReceipt";
	Validation.HandlerChecks           = "_DemoStandardSubsystems.CheckCommentInGoodsReceipt";
	Validation.CheckStartDate           = Date('20140101000000');
	Validation.IssuesLimit                 = 3;
	Validation.ImportanceChangeDenied   = False;
	Validation.AccountingChecksContext = "_DemoAccountingChecks";
	Validation.Comment                  = NStr("ru = 'Демонстрационная проверка.';
												|en = 'Demo check.';");
	Validation.SupportsRandomCheck = True;
	
	Validation = Checks.Add();
	Validation.GroupID          = ChecksGroup.Id;
	Validation.Description                 = NStr("ru = 'Проверка проведения документа ""Демо: Счет фактура полученный""';
												|en = 'Check for posting the document ""Demo: Received tax invoice""';");
	Validation.Reasons                      = NStr("ru = 'Документ не проведен.';
												|en = 'Document is not posted.';");
	Validation.Recommendation                 = NStr("ru = 'Провести документ.';
												|en = 'Post the document.';");
	Validation.Id                = "Demo.CheckReceivedTaxInvoicePosting";
	Validation.HandlerChecks           = "_DemoStandardSubsystems.CheckReceivedTaxInvoicePosting";
	Validation.GoToCorrectionHandler = "_DemoStandardSubsystemsClient.PostTaxInvoicesForTroublesomeCounterparties";
	Validation.ImportanceChangeDenied   = True;
	Validation.AccountingChecksContext = "_DemoAccountingChecks";
	Validation.SupportsRandomCheck = False;
	
EndProcedure

// See AccountingAuditOverridable.OnDetermineIndicationGroupParameters
Procedure OnDetermineIndicationGroupParameters(IndicationGroupParameters, Val ObjectWithIssueType) Export
	
	If ObjectWithIssueType = Type("DocumentRef._DemoPayrollAccrual") Then
		IndicationGroupParameters.OutputAtBottom = True;
	ElsIf ObjectWithIssueType = Type("DocumentRef._DemoTaxInvoiceReceived") Then
		IndicationGroupParameters.DetailedKind = False;
	EndIf;
	
EndProcedure

// See AccountingAuditOverridable.OnDetermineIndicatiomColumnParameters.
Procedure OnDetermineIndicatiomColumnParameters(IndicationColumnParameters, FullName) Export
	If FullName = Metadata.Documents._DemoPayrollAccrual.FullName() Then
		IndicationColumnParameters.OutputLast = True;
	EndIf;
EndProcedure

// See AccountingAuditOverridable.BeforeWriteIssue.
Procedure BeforeWriteIssue(Issue1, ObjectReference, Attributes) Export
	If Attributes.Find("Organization") <> Undefined Then
		Issue1.Insert("_DemoCompany", Common.ObjectAttributeValue(ObjectReference, "Organization"));
	EndIf;
EndProcedure

// Checks for filled comments in the _DemoGoodsReceipt document.
// Showcase of applied data integrity check implementation.
//
// Parameters:
//   Validation            - CatalogRef.AccountingCheckRules
//   CheckParameters   - See AccountingAudit.IssueDetails.CheckParameters
//
Procedure CheckCommentInGoodsReceipt(Validation, CheckParameters) Export
	
	ObjectsToCheck = Undefined;
	CheckParameters.Property("ObjectsToCheck", ObjectsToCheck);
	
	Query = New Query;
	CommonQueryText = 
	"SELECT
	|	_DemoGoodsReceipt.Ref AS ObjectWithIssue,
	|	_DemoGoodsReceipt.EmployeeResponsible AS EmployeeResponsible,
	|	_DemoGoodsReceipt.Comment AS Comment,
	|	_DemoGoodsReceipt.PointInTime AS PointInTime
	|FROM
	|	Document._DemoGoodsReceipt AS _DemoGoodsReceipt
	|WHERE
	|	&Condition
	|	AND _DemoGoodsReceipt.Comment LIKE """"
	|	AND &RestrictionByDate";
	
	If ObjectsToCheck <> Undefined Then
		Query.SetParameter("Ref", ObjectsToCheck);
		Condition = "_DemoGoodsReceipt.Ref IN (&Ref)";
	Else
		Condition = "TRUE";
	EndIf;
	
	If ValueIsFilled(CheckParameters.CheckStartDate) Then
		RestrictionByDate = "_DemoGoodsReceipt.Date >= &CheckStartDate";
	Else
		RestrictionByDate = "True";
	EndIf;
	
	CommonQueryText = StrReplace(CommonQueryText, "&Condition", Condition);
	CommonQueryText = StrReplace(CommonQueryText, "&RestrictionByDate", RestrictionByDate);
	
	Query.Text = CommonQueryText;
	Query.SetParameter("CheckStartDate", CheckParameters.CheckStartDate);
	
	Result = Query.Execute().Select();
	While Result.Next() Do
		
		Issue1 = AccountingAudit.IssueDetails(Result.ObjectWithIssue, CheckParameters);
		
		Issue1.IssueSummary = ?(ValueIsFilled(Result.Comment), NStr("ru = 'В комментарии введены пробелы или табуляции.';
																						|en = 'There are spaces or tabulations in the comment.';"), NStr("ru = 'Не введен комментарий в документе.';
																																					|en = 'A comment is not entered in the document.';"));
		Issue1.EmployeeResponsible     =  Result.EmployeeResponsible;
		
		AccountingAudit.WriteIssue(Issue1, CheckParameters);
		
	EndDo;
	
EndProcedure

// Checks if the _DemoTaxInvoiceReceived documents are posted broken down by counterparties.
// Showcase of managing check kinds and their properties.
//
// Parameters:
//   Validation            - CatalogRef.AccountingCheckRules
//   CheckParameters   - See AccountingAudit.IssueDetails.CheckParameters
//
Procedure CheckReceivedTaxInvoicePosting(Validation, CheckParameters) Export
	
	QueryText = 
		"SELECT
		|	_DemoTaxInvoiceReceived.Ref AS ObjectWithIssue,
		|	_DemoTaxInvoiceReceived.PointInTime AS PointInTime,
		|	_DemoTaxInvoiceReceived.Posted AS Posted,
		|	_DemoTaxInvoiceReceived.Counterparty AS Counterparty
		|FROM
		|	Document._DemoTaxInvoiceReceived AS _DemoTaxInvoiceReceived
		|WHERE
		|	&Condition
		|	AND NOT _DemoTaxInvoiceReceived.Posted
		|
		|ORDER BY
		|	PointInTime DESC
		|TOTALS BY
		|	Counterparty";
	
	QueryOptions = New Structure;
	Counterparties = New Array;
	For Each ExecutionParameter In CheckParameters.CheckExecutionParameters Do
		CounterpartyToCheck = Undefined;
		If ExecutionParameter.Property("Property2", CounterpartyToCheck) Then
			Counterparties.Add(CounterpartyToCheck);
		EndIf;
	EndDo;
	
	If Counterparties.Count() > 0 Then
		Condition = "_DemoTaxInvoiceReceived.Counterparty IN (&Counterparties)";
		QueryOptions.Insert("Counterparties", Counterparties);
	Else
		Condition = "TRUE";
	EndIf;
	
	QueryText = StrReplace(QueryText, "&Condition", Condition);
	
	If ValueIsFilled(CheckParameters.CheckStartDate) Then
		RestrictionByDate = "_DemoTaxInvoiceReceived.Date >= &CheckStartDate";
	Else
		RestrictionByDate = "TRUE";
	EndIf;
	
	QueryText = StrReplace(QueryText, "&RestrictionByDate", RestrictionByDate);
	If ValueIsFilled(CheckParameters.CheckStartDate) Then
		QueryOptions.Insert("CheckStartDate", CheckParameters.CheckStartDate);
	EndIf;
	
	Query = New Query(QueryText);
	For Each QueryParameter In QueryOptions Do
		Query.SetParameter(QueryParameter.Key, QueryParameter.Value);
	EndDo;
	
	Result = Query.Execute().Select(QueryResultIteration.ByGroups);
	While Result.Next() Do
		
		// Clear previous check results by the counterparty.
		CheckExecutionParameters = AccountingAudit.CheckExecutionParameters("_DemoAccountingChecks", Result.Counterparty);
		AccountingAudit.ClearPreviousCheckResults(Validation, CheckExecutionParameters);
		
		CheckKind = AccountingAudit.CheckKind(CheckExecutionParameters);
		
		DetailedResult = Result.Select();
		While DetailedResult.Next() Do
		
			If DetailedResult.Posted Then
				Continue;
			EndIf;
			
			// An unposted document found.
			Issue1 = AccountingAudit.IssueDetails(DetailedResult.ObjectWithIssue, CheckParameters);
			Issue1.CheckKind = CheckKind;
			Issue1.IssueSummary = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'По контрагенту ""%1"" имеется непроведенный документ ""%2""';
					|en = 'There is an unposted ""%2"" document by the ""%1"" counterparty';"),
				Result.Counterparty, DetailedResult.ObjectWithIssue);
			
			AccountingAudit.WriteIssue(Issue1, CheckParameters);
			
		EndDo;
	EndDo;
	
EndProcedure

#EndRegion

#Region IBVersionUpdate

// The initial population.
//

// Called by the PerformerRoles catalog manager module at the business role initial population.
// 
//
// Parameters:
//  LanguagesCodes - Array - List of configuration languages. Applicable to multilingual configurations.
//  Items   - ValueTable - Fill data. LIst of columns repeats the list of attributes in the ImplementersRoles catalog. 
//                                 
//  TabularSections - Structure - Object table details, where:
//   * Key - String - Table name.
//   * Value - ValueTable - Value table.
//                                  Its structure must be copied before population. For example:
//                                  Item.Keys = TabularSections.Keys.Copy();
//                                  TSItem = Item.Keys.Add();
//                                  TSItem.KeyName = "Primary";
//
Procedure OnInitiallyFillPerformersRoles(LanguagesCodes, Items, TabularSections) Export
	
	FoundItem = Items.Find("EmployeeResponsibleForTasksManagement", "PredefinedDataName");
	If FoundItem <> Undefined Then
		FoundItem.Purpose.Clear();
		TSItem = FoundItem.Purpose.Add();
		TSItem.UsersType = Catalogs._DemoPartnersContactPersons.EmptyRef();
		TSItem = FoundItem.Purpose.Add();
		TSItem.UsersType = Catalogs._DemoPartners.EmptyRef();
		TSItem = FoundItem.Purpose.Add();
		TSItem.UsersType = Catalogs.Users.EmptyRef();
	EndIf;
	
	Item = Items.Add();
	Item.PredefinedDataName = "_DemoChiefAccountant";
	Item.UsedWithoutAddressingObjects = False;
	Item.UsedByAddressingObjects  = True;
	Item.MainAddressingObjectTypes    = ChartsOfCharacteristicTypes.TaskAddressingObjects._DemoCompany;
	Item.ExternalRole                      = False;
	Item.Code                              = "000000005";
	Item.BriefPresentation             = NStr("ru = '000000005';
													|en = '000000005';", Common.DefaultLanguageCode());
	
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description",
		"ru = 'Демо: Главный бухгалтер';
		|en = 'Demo: Chief accountant';", LanguagesCodes); // @NStr-1
	
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Comment",
		"ru = 'Доступна внешним пользователям';
		|en = 'Available to external users';",LanguagesCodes); // @NStr-1
	
	Purpose = TabularSections.Purpose.Copy(); // ValueTable
	TSItem = Purpose.Add();
	TSItem.UsersType = Catalogs.Users.EmptyRef();
	Item.Purpose = Purpose;
	
	Item = Items.Add();
	Item.PredefinedDataName = "_DemoCEO";
	Item.UsedWithoutAddressingObjects = True;
	Item.UsedByAddressingObjects  = False;
	Item.ExternalRole                      = False;
	Item.Code                              = "000000002";
	Item.BriefPresentation             = NStr("ru = '000000002';
													|en = '000000002';", Common.DefaultLanguageCode());
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description",
		"ru = 'Демо: Руководитель компании';
		|en = 'Demo: CEO';", LanguagesCodes); // @NStr-1
	
	Purpose = TabularSections.Purpose.Copy(); // ValueTable
	TSItem = Purpose.Add();
	TSItem.UsersType = Catalogs.Users.EmptyRef();
	Item.Purpose = Purpose;
	
	Item = Items.Add();
	Item.PredefinedDataName = "_DemoDepartmentManager";
	Item.UsedWithoutAddressingObjects = False;
	Item.UsedByAddressingObjects  = True;
	Item.MainAddressingObjectTypes    = ChartsOfCharacteristicTypes.TaskAddressingObjects._DemoDepartment;
	Item.ExternalRole                      = False;
	Item.Code                              = "000000003";
	Item.BriefPresentation             = NStr("ru = '000000003';
													|en = '000000003';", Common.DefaultLanguageCode());
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description",
		"ru = 'Демо: Руководитель подразделения';
		|en = 'Demo: Department manager';", LanguagesCodes); // @NStr-1
	
	Purpose = TabularSections.Purpose.Copy(); // ValueTable
	TSItem = Purpose.Add();
	TSItem.UsersType = Catalogs.Users.EmptyRef();
	Item.Purpose = Purpose;
	
	Item = Items.Add();
	Item.PredefinedDataName = "_DemoProjectManager";
	Item.UsedWithoutAddressingObjects = False;
	Item.UsedByAddressingObjects  = True;
	Item.MainAddressingObjectTypes    = ChartsOfCharacteristicTypes.TaskAddressingObjects._DemoProject;
	Item.ExternalRole                      = False;
	Item.Code                              = "000000004";
	Item.BriefPresentation             = NStr("ru = '000000004';
													|en = '000000004';", Common.DefaultLanguageCode());
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description",
		"ru = 'Демо: Руководитель проекта';
		|en = 'Demo: Project manager';", LanguagesCodes); // @NStr-1
	
	Purpose = TabularSections.Purpose.Copy(); // ValueTable
	TSItem = Purpose.Add();
	TSItem.UsersType = Catalogs.Users.EmptyRef();
	Item.Purpose = Purpose;
	
EndProcedure

// Called by the PerformerRoles catalog manager module at the business role initial population.
// 
//
// Parameters:
//  Object                  - CatalogObject.PerformerRoles - Object to populate.
//  Data                  - ValueTableRow - Fill data.
//  AdditionalParameters - Structure
//
Procedure AtInitialPerformerRoleFilling(Object, Data, AdditionalParameters) Export
	
EndProcedure

// Called by the CCT TaskAddressingObjects manager module on the task initial population.
// Standard attribute ValueType must populated in the OnInitialFillingTaskAddressingObjectItem procedure.
// 
//
// Parameters:
//  LanguagesCodes - Array - List of configuration languages. Applicable to multilingual configurations.
//  Items   - ValueTable - Fill data. List of columns repeats the set of attributes in charts of characteristic types TaskAddressingObjects.
//  TabularSections - Structure - Object table details, where:
//   * Key - String - Table name.
//   * Value - ValueTable - Value table.
//                                  Its structure must be copied before population. For example:
//                                  Item.Keys = TabularSections.Keys.Copy();
//                                  TSItem = Item.Keys.Add();
//                                  TSItem.KeyName = "Primary";
//
Procedure OnInitialFillingTasksAddressingObjects(LanguagesCodes, Items, TabularSections) Export
	
	Item = Items.Add();
	Item.PredefinedDataName = "_DemoCompany";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description",
		"ru = 'Демо: Организация';
		|en = 'Demo: Company';", LanguagesCodes); // @NStr-2
	
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef._DemoCompanies"));
	AllowedTypes = New TypeDescription(TypesArray);
	Item.ValueType = AllowedTypes;
	
	Item = Items.Add();
	Item.PredefinedDataName = "_DemoDepartment";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description",
		"ru = 'Демо: Подразделение';
		|en = 'Demo: Department';", LanguagesCodes); // @NStr-2
	
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef._DemoDepartments"));
	
	AllowedTypes = New TypeDescription(TypesArray);
	Item.ValueType = AllowedTypes;
	
	Item = Items.Add();
	Item.PredefinedDataName = "_DemoProject";
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description",
		"ru = 'Демо: Проект';
		|en = 'Demo: Project';", LanguagesCodes); // @NStr-2
	
	TypesArray = New Array;
	TypesArray.Add(Type("CatalogRef._DemoProjects"));
	
	AllowedTypes = New TypeDescription(TypesArray);
	Item.ValueType = AllowedTypes;
	
EndProcedure

// Called by the CCT TaskAddressingObjects manager module on the task initial population.
// 
//
// Parameters:
//  Object                  - ChartOfCharacteristicTypesObject.TaskAddressingObjects - Object to populate.
//  Data                  - ValueTableRow - Fill data.
//  AdditionalParameters - Structure
//
Procedure OnInitialFillingTaskAddressingObjectItem(Object, Data, AdditionalParameters) Export
	
	If Object.PredefinedDataName = "AllAddressingObjects" Then
		
		TypesArray = New Array;
		TypesArray.Add(Type("CatalogRef._DemoDepartments"));
		TypesArray.Add(Type("CatalogRef._DemoCompanies"));
		TypesArray.Add(Type("CatalogRef._DemoProjects"));
		
		AllowedTypes = New TypeDescription(TypesArray);
		Object.ValueType = AllowedTypes;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region DocumentRecordsReport

// See DocumentRecordsReportOverridable.OnDetermineRegistersWithRecords.
Procedure OnDetermineRegistersWithRecords(Document, RegistersWithRecords) Export
	
	If TypeOf(Document) = Type("DocumentRef._DemoGoodsReceipt") Then
		RegistersWithRecords.Insert(Metadata.InformationRegisters.ObjectsVersions, "Object");
	EndIf;
	
EndProcedure

// See DocumentRecordsReportOverridable.OnCalculateRecordsCount.
Procedure OnCalculateRecordsCount(Document, CalculatedCount) Export
	
	If TypeOf(Document) <> Type("DocumentRef._DemoGoodsReceipt")
		Or Not AccessRight("View", Metadata.InformationRegisters.ObjectsVersions) Then
		Return;
	EndIf;
	
	Query = New Query(
	"SELECT ALLOWED
	|	COUNT(*) AS Count
	|FROM
	|	InformationRegister.ObjectsVersions AS ObjectsVersions
	|WHERE
	|	ObjectsVersions.Object = &Document");
	
	Query.SetParameter("Document", Document);
	Selection = Query.Execute().Select();
	
	CalculatedCount.Insert(
		StrReplace(Metadata.InformationRegisters.ObjectsVersions.FullName(), ".", "_"),
		?(Selection.Next(), Selection.Count, 0));
	
EndProcedure

// See DocumentRecordsReportOverridable.OnPrepareDataSet.
Procedure OnPrepareDataSet(Document, DataSets) Export
	
	If TypeOf(Document) <> Type("DocumentRef._DemoGoodsReceipt") Then
		Return;
	EndIf;
	
	MetadataObject = Metadata.InformationRegisters.ObjectsVersions;
	FullRegisterName = StrReplace(MetadataObject.FullName(), ".", "_");
	
#Region DataSetQueryTextInitialization
	
	StandardAttributes = FieldsPresentationNames(MetadataObject.StandardAttributes);
	RegisterDimensions = FieldsPresentationNames(MetadataObject.Dimensions);
	RegisterResources = FieldsPresentationNames(MetadataObject.Resources);
	RegisterAttributes1 = FieldsPresentationNames(MetadataObject.Attributes);
	
	SelectionFields = "";
	AddFields(SelectionFields, StandardAttributes);
	AddFields(SelectionFields, RegisterDimensions);
	AddFields(SelectionFields, RegisterResources);
	AddFields(SelectionFields, RegisterAttributes1);
	
	MaxFields = Max(StandardAttributes.Count(),
		RegisterDimensions.Count(),
		RegisterResources.Count(),
		RegisterAttributes1.Count());
	
	AddFieldsNumbers(SelectionFields, FieldsNumbers(MaxFields));
	
	QueryText =
	"SELECT ALLOWED
	|	1 AS RegisterRecordCount1,
	|	""&RegisterName"" AS RegisterName,
	|	&Fields
	|FROM
	|	InformationRegister.ObjectsVersions AS CurrentTable
	|WHERE
	|	CurrentTable.Object = &OwnerDocument
	|{WHERE
	|	(&CompositionCondition)}";
	
	QueryText = StrReplace(QueryText, "&RegisterName", FullRegisterName);
	QueryText = StrReplace(QueryText, "&Fields", SelectionFields);
	QueryText = StrReplace(QueryText, "&CompositionCondition", """" + FullRegisterName + """ IN (&RegistersList)");
	
#EndRegion
	
#Region OverridingDataSetQueryText
	
	DataSetsBoundary = DataSets.UBound();
	CurrentDataSetIndex = -1;
	CurrentDataSet = Undefined;
	
	For IndexOf = 0 To DataSetsBoundary Do
		DataSet = DataSets[IndexOf];
		If DataSet.FullRegisterName <> FullRegisterName Then
			Continue;
		EndIf;
		
		DataSet.QueryText = QueryText;
		
		CurrentDataSetIndex = IndexOf;
		CurrentDataSet = DataSet;
		
		Break;
	EndDo;
	
	If CurrentDataSetIndex < 0
		Or CurrentDataSetIndex = DataSetsBoundary Then 
		Return;
	EndIf;
	
	DataSets.Delete(CurrentDataSetIndex);
	DataSets.Add(CurrentDataSet);
	
#EndRegion
	
EndProcedure

#EndRegion

#Region Print

//  See PrintManagementOverridable.OnDefinePrintDataSources
Procedure OnDefinePrintDataSources(Object, PrintDataSources) Export
	
	
	If Object = "Catalog._DemoIndividuals.Description" Then
		PrintDataSources.Add(SchemeDataPrintsLastNameInitials(), "DataPrintLastNameInitials");
	EndIf;
	
	If StrEndsWith(Object, ".Barcode") Then
		PrintDataSources.Add(SchemaPrintDataBarcodes(), "Barcodes");
	EndIf;
	
EndProcedure

// See PrintManagementOverridable.WhenPreparingPrintData
Procedure WhenPreparingPrintData(DataSources, ExternalDataSets, DataCompositionSchemaId, LanguageCode,
	AdditionalParameters) Export
	
	
	If DataCompositionSchemaId = "Barcodes" Then
		ExternalDataSets.Insert("Data", PrintDataBarcodes(DataSources));
	EndIf;
	
EndProcedure

#EndRegion

#Region AttachableCommands

// See AttachableCommandsOverridable.OnDefineCommandsAttachedToObject.
Procedure OnDefineCommandsAttachedToObject(FormSettings, Sources, AttachedReportsAndDataProcessors, Commands) Export
	
	FoundItems = AttachedReportsAndDataProcessors.FindRows(New Structure("AddSendInvitationCommands", True));
	For Each AttachedObject In FoundItems Do
		AttachedObject.Manager.AddSendInvitationCommands(Commands, FormSettings);
	EndDo;
	
	If Sources.Rows.Find(Metadata.Documents.Questionnaire, "Metadata") <> Undefined Then
		Command = Commands.Add();
		Command.Kind = "Surveys";
		Command.Presentation = NStr("ru = 'Демо: Примечание';
									|en = 'Demo: Note';");
		Command.WriteMode = "NotWrite";
		Command.VisibilityInForms = "DocumentForm";
		Command.Handler = "_DemoStandardSubsystemsClient.FillNote";
		AttachableCommands.AddCommandVisibilityCondition(Command, "SurveyMode", Enums.SurveyModes.Interview);
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.UserReminders") Then
		Command = Commands.Add();
		Command.Kind = "Organizer";
		Command.Presentation = NStr("ru = 'Демо: Напомнить за 5 минут';
									|en = 'Demo: Remind me in 5 minutes';");
		Command.Picture = PictureLib.Reminder;
		Command.ParameterType = New TypeDescription("TaskRef.PerformerTask");
		Command.WriteMode = "NotWrite";
		Command.Order = 50;
		Command.Handler = "_DemoUserRemindersClient.Remind5MinAhead"; 
		Command.MultipleChoice = False;
		
		Command = Commands.Add();
		Command.Kind = "Organizer";
		Command.Presentation = NStr("ru = 'Демо: Напомнить через 10 минут';
									|en = 'Demo: Remind me in 10 minutes';");
		Command.Picture = PictureLib.Reminder;
		Command.ParameterType = New TypeDescription("CatalogRef._DemoCounterparties");
		Command.WriteMode = "NotWrite";
		Command.Order = 50;
		Command.Handler = "_DemoUserRemindersClient.RemindIn10Min"; 
		Command.MultipleChoice = False;
		
		Command = Commands.Add();
		Command.Kind = "Organizer";
		Command.Presentation = NStr("ru = 'Демо: Напомнить о дне рождения за 3 дня';
									|en = 'Demo: Remind me about the birthday 3 days before it';");
		Command.Picture = PictureLib.Reminder;
		Command.ParameterType = New TypeDescription("CatalogRef._DemoIndividuals");
		Command.WriteMode = "NotWrite";
		Command.Order = 50;
		Command.Handler = "_DemoUserRemindersClient.RemindOfBirthday3DaysAhead"; 
		Command.MultipleChoice = False;
	EndIf;
	
	
EndProcedure

// See GenerateFromOverridable.OnAddGenerationCommands.
Procedure OnAddGenerationCommands(Object, GenerationCommands, Parameters, StandardProcessing) Export
	
	If Object = Metadata.Catalogs.Users
		Or Object = Metadata.Catalogs.Files Then
		
		BusinessProcesses._DemoJobWithRoleAddressing.AddGenerateCommand(GenerationCommands);
		
	ElsIf Object = Metadata.Documents.Meeting 
		Or Object = Metadata.Documents.PhoneCall
		Or Object = Metadata.Documents.IncomingEmail
		Or Object = Metadata.Documents.OutgoingEmail Then
		
		Documents._DemoSalesOrder.AddGenerateCommand(GenerationCommands);
		
	EndIf;
	
EndProcedure

// See GenerateFromOverridable.OnDefineObjectsWithCreationBasedOnCommands.
Procedure OnDefineObjectsWithCreationBasedOnCommands(Objects) Export

	Objects.Add(Metadata.Documents._DemoSalesOrder);
	Objects.Add(Metadata.Documents._DemoGoodsReceipt);
	Objects.Add(Metadata.Documents._DemoGoodsSales);
	Objects.Add(Metadata.Documents._DemoGoodsWriteOff);
	Objects.Add(Metadata.Documents._DemoCustomerProformaInvoice);
	Objects.Add(Metadata.BusinessProcesses._DemoJobWithRoleAddressing);

EndProcedure

#EndRegion

#Region DuplicateObjectsDetection

// See DuplicateObjectsDetectionOverridable.OnDefineDuplicatesSearchParameters.
Procedure OnDefineDuplicatesSearchParameters(Val MetadataObjectName, SearchParameters, Val AdditionalParameters,
	StandardProcessing) Export
	
	If MetadataObjectName = Metadata.Catalogs._DemoPartners.FullName() 
		Or MetadataObjectName = Metadata.Catalogs._DemoCompanies.FullName() Then
		SearchParameters.StringsComparisonForSimilarity.ExceptionWords = LegalFormsAbbreviations();
	EndIf;	
	
EndProcedure

#EndRegion

#Region Users

// See UsersOverridable.OnDefineRoleAssignment
Procedure OnDefineRoleAssignment(RolesAssignment) Export
	
	// ForExternalUsersOnly.
	RolesAssignment.ForExternalUsersOnly.Add(
		Metadata.Roles._DemoInvoicesPaymentByExternalUsers.Name);
	
	RolesAssignment.ForExternalUsersOnly.Add(
		Metadata.Roles._DemoReadAuthorizationObjectsData.Name);
	
	RolesAssignment.ForExternalUsersOnly.Add(
		Metadata.Roles._DemoReadAdditionalReportsAndDataProcessors.Name);
	
	// BothForUsersAndExternalUsers.
	RolesAssignment.BothForUsersAndExternalUsers.Add(
		Metadata.Roles._DemoReadDataForAnswersToQuestionnaireQuestions.Name);
	
EndProcedure

// See UsersOverridable.OnSetInitialSettings.
Procedure OnSetInitialSettings(InitialSettings1) Export
	
	LeftGroup2 = New ClientApplicationInterfaceContentSettingsGroup;
	LeftGroup2.Add(New ClientApplicationInterfaceContentSettingsItem("SectionsPanel"));
	
	TopGroup = New ClientApplicationInterfaceContentSettingsGroup;
	TopGroup.Add(New ClientApplicationInterfaceContentSettingsItem("OpenItemsPanel"));
	
	CompositionSettings1 = New ClientApplicationInterfaceContentSettings;
	CompositionSettings1.Left.Add(LeftGroup2);
	CompositionSettings1.Top.Add(TopGroup);
	
	InitialSettings1.ClientSettings.ClientApplicationInterfaceVariant = ClientApplicationInterfaceVariant.Taxi;
	InitialSettings1.InterfaceSettings.SectionsPanelRepresentation = SectionsPanelRepresentation.PictureAndText;
	InitialSettings1.TaxiSettings.SetContent(CompositionSettings1);
	
EndProcedure

// See UsersOverridable.OnGetOtherSettings.
Procedure OnGetOtherSettings(UserInfo, Settings) Export
	
	// Get the value of the AskConfirmationOnExit setting.
	SettingValue = Common.CommonSettingsStorageLoad(
		"UserCommonSettings", "AskConfirmationOnExit",,,
			UserInfo.InfobaseUserName);
	
	If SettingValue <> Undefined Then
		
		ValueListSettings = New ValueList;
		ValueListSettings.Add(SettingValue);
		
		SettingInformation    = New Structure;
		SettingInformation.Insert("SettingName1", NStr("ru = 'Подтверждение при закрытии приложения';
																|en = 'Confirmation on exit';"));
		SettingInformation.Insert("PictureSettings", "");
		SettingInformation.Insert("SettingsList", ValueListSettings);
		
		Settings.Insert("AskConfirmationOnClose", SettingInformation);
	EndIf;
	
EndProcedure

// See UsersOverridable.OnSaveOtherSetings.
Procedure OnSaveOtherSetings(UserInfo, Settings) Export
	
	If Settings.SettingID = "AskConfirmationOnClose" Then
		SettingValue = Settings.SettingValue[0];
		Common.CommonSettingsStorageSave(
			"UserCommonSettings", "AskConfirmationOnExit",
			SettingValue.Value,, UserInfo.InfobaseUserName);
	EndIf;
	
EndProcedure

// See UsersOverridable.OnDeleteOtherSettings.
Procedure OnDeleteOtherSettings(UserInfo, Settings) Export
	
	If Settings.SettingID = "AskConfirmationOnClose" Then
		Common.CommonSettingsStorageDelete(
			"UserCommonSettings", "AskConfirmationOnExit",
			UserInfo.InfobaseUserName);
	EndIf;
	
EndProcedure

#EndRegion

#Region ReportMailing

// See ReportMailingOverridable.DetermineReportsToExclude
Procedure WhenDefiningExcludedReports(ReportsToExclude) Export
	
	ReportsToExclude.Add(Metadata.Reports.BackgroundUpdateHandlersStatistics);
	
EndProcedure

// See ReportMailingOverridable.OnDefineEmailTextParameters
Procedure OnDefineEmailTextParameters(BulkEmailType, MailingRecipientType, AdditionalTextParameters) Export
	
	If BulkEmailType = "Personalized" 
		And MailingRecipientType = New TypeDescription("CatalogRef._DemoIndividuals") Then
		AdditionalTextParameters.Insert("Name", NStr("ru = 'Имя';
															|en = 'First name';"));
		AdditionalTextParameters.Insert("MiddleName", NStr("ru = 'Отчество';
																|en = 'Middle name';"));
	EndIf;
	
EndProcedure

// See ReportMailingOverridable.OnReceiveEmailTextParameters
Procedure OnReceiveEmailTextParameters(BulkEmailType, MailingRecipientType, Recipient, AdditionalTextParameters) Export
	
	If BulkEmailType = "Personalized" And MailingRecipientType
		= New TypeDescription("CatalogRef._DemoIndividuals") And Recipient <> Undefined Then
		AttributesOfIndividual = Common.ObjectAttributesValues(Recipient, "Name, MiddleName");
		AdditionalTextParameters.Name      = AttributesOfIndividual.Name;
		AdditionalTextParameters.MiddleName = AttributesOfIndividual.MiddleName;
	EndIf;
	
EndProcedure

// See ReportMailingOverridable.BeforeGenerateMailingRecipientsList
Procedure BeforeGenerateMailingRecipientsList(RecipientsParameters, Query, StandardProcessing, Result) Export
	
	If RecipientsParameters.Personal Then
		RecipientsType = TypeOf(RecipientsParameters.Author);
	Else
		MetadataObjectKey = ?(ValueIsFilled(RecipientsParameters.MailingRecipientType),
			Common.ObjectAttributeValue(RecipientsParameters.MailingRecipientType, "MetadataObjectKey"), Undefined);
		RecipientsType = ?(MetadataObjectKey <> Undefined, MetadataObjectKey.Get(), Undefined);
	EndIf;
	
	If RecipientsType = Type("CatalogRef._DemoPartnersContactPersons") Then
		
		Query.Text =
		"SELECT
		|	TableOfRecipients.Recipient AS Recipient,
		|	TableOfRecipients.Excluded AS Excluded
		|INTO TableOfRecipients
		|FROM
		|	&TableOfRecipients AS TableOfRecipients
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED DISTINCT
		|	Recipients.Ref AS Recipient,
		|	Contacts.Presentation AS EMail,
		|	Recipients.Description AS Description
		|
		|FROM
		|	Catalog._DemoPartnersContactPersons AS Recipients
		|		LEFT JOIN Catalog._DemoPartnersContactPersons.ContactInformation AS Contacts
		|		ON (Contacts.Ref = Recipients.Ref)
		|			AND (Contacts.Kind = &RecipientsEmailAddressKind)
		|WHERE
		|	Recipients.Ref IN
		|			(SELECT
		|				TableOfRecipients.Recipient
		|			FROM
		|				TableOfRecipients
		|			WHERE
		|				NOT TableOfRecipients.Excluded)
		|	AND NOT Recipients.Ref IN
		|				(SELECT
		|					TableOfRecipients.Recipient
		|				FROM
		|					TableOfRecipients
		|				WHERE
		|					TableOfRecipients.Excluded)
		|	AND NOT Recipients.DeletionMark
		|	AND (Recipients.RelationEndDate = DATETIME(1, 1, 1)
		|			OR Recipients.RelationEndDate >= &CurrentDate)"; 
		
		Query.SetParameter("CurrentDate", BegOfDay(CurrentSessionDate()));
		
	EndIf;
	
EndProcedure

// See ReportMailingOverridable.BeforeSaveSpreadsheetDocumentToFormat
Procedure BeforeSaveSpreadsheetDocumentToFormat(StandardProcessing, SpreadsheetDocument, Format, FullFileName) Export
	
	If Format = Enums.ReportSaveFormats._DemoHTML3 Then
		StandardProcessing = False;
		FullFileName = FullFileName +".html";
		SpreadsheetDocument.Write(FullFileName, SpreadsheetDocumentFileType.HTML3);
	EndIf;
	
EndProcedure

// See ReportMailingOverridable.OnPrepareReportGenerationParameters
Procedure OnPrepareReportGenerationParameters(GenerationParameters, AdditionalParameters) Export 
	
	If Not AdditionalParameters.DCS Then
		Return;
	EndIf;
	
	Settings = AdditionalParameters.DCSettingsComposer.GetSettings();
	Settings.AdditionalProperties.Insert("ReportDistributionInProgress", True);
	
	GenerationParameters.Insert("DCSettings", Settings);
	
EndProcedure

#EndRegion

#Region ToDoList

// Parameters:
//   ToDoList - See ToDoListServer.ToDoList.
//
Procedure OnFillToDoList(ToDoList) Export
	
	If Not AccountingAudit.SubsystemAvailable() Then
		Return;
	EndIf;
	
	CheckKind = AccountingAudit.CheckKind("_DemoAccountingChecks");
	Issues    = AccountingAudit.SummaryInformationOnChecksKinds(CheckKind, , True);
	Sections     = ToDoListServer.SectionsForObject(Metadata.Reports.AccountingCheckResults.FullName());
	
	For Each Section In Sections Do
		
		ToDoItem = ToDoList.Add();
		ToDoItem.Id  = "_DemoAccountingChecks" + StrReplace(Section.FullName(), ".", "_");
		ToDoItem.HasToDoItems       = Issues.Count > 0;
		ToDoItem.Important         = Issues.HasErrors;
		ToDoItem.Owner       = Section;
		ToDoItem.Presentation  = NStr("ru = 'Некорректные документы';
									|en = 'Incorrect documents';");
		ToDoItem.ToolTip      = NStr("ru = 'Незаполненные комментарии в документах поступления товаров, непроведенные счета-фактуры и другие проблемы ведения учета.';
									|en = 'Blank comments in goods receipt documents, unposted tax invoices, and other integrity issues.';");
		ToDoItem.Count     = Issues.Count;
		ToDoItem.FormParameters = New Structure("CheckKind", CheckKind);
		ToDoItem.Form          = "Report.AccountingCheckResults.Form";
	EndDo;
	
EndProcedure

#EndRegion

#Region AccessManagement

// See AccessManagementOverridable.OnFillAccessKinds.
Procedure OnFillAccessKinds(AccessKinds) Export
	
	AccessKind = AccessKinds.Add();
	AccessKind.Name = "_DemoProductGroups";
	AccessKind.Presentation    = NStr("ru = 'Демо: Группы номенклатуры';
										|en = 'Demo: Product groups';");
	AccessKind.ValuesType      = Type("CatalogRef._DemoProducts");
	AccessKind.ValuesGroupsType = Type("CatalogRef._DemoProductAccessGroups");
	AccessManagement.AddExtraAccessKindTypes(AccessKind,
		Type("CatalogRef._DemoProductsKinds"),
		Type("CatalogRef._DemoProductAccessGroups"));
	
	AccessKind = AccessKinds.Add();
	AccessKind.Name = "_DemoCashAccounts";
	AccessKind.Presentation = NStr("ru = 'Демо: Кассы';
									|en = 'Demo: Cash accounts';");
	AccessKind.ValuesType   = Type("CatalogRef._DemoCashAccounts");
	AccessManagement.AddExtraAccessKindTypes(AccessKind,
		Type("CatalogRef._DemoCashRegisters"));
	
	AccessKind = AccessKinds.Add();
	AccessKind.Name = "_DemoStorageLocations";
	AccessKind.Presentation = NStr("ru = 'Демо: Места хранения';
									|en = 'Demo: Storage locations';");
	AccessKind.ValuesType   = Type("CatalogRef._DemoStorageLocations");
	
	AccessKind = AccessKinds.Add();
	AccessKind.Name = "_DemoPartnerGroups";
	AccessKind.Presentation    = NStr("ru = 'Демо: Группы партнеров';
										|en = 'Demo: Partner groups';");
	AccessKind.ValuesType      = Type("CatalogRef._DemoPartners");
	AccessKind.ValuesGroupsType = Type("CatalogRef._DemoPartnersAccessGroups");
	
	AccessKind = AccessKinds.Add();
	AccessKind.Name = "_DemoIndividuals";
	AccessKind.Presentation    = NStr("ru = 'Демо: Физические лица';
										|en = 'Demo: Individuals';");
	AccessKind.ValuesType      = Type("CatalogRef._DemoIndividuals");
	
	AccessKind = AccessKinds.Add();
	AccessKind.Name = "_DemoBusinessOperations";
	AccessKind.Presentation = NStr("ru = 'Демо: Хозяйственные операции';
									|en = 'Demo: Business transactions';");
	AccessKind.ValuesType   = Type("EnumRef._DemoBusinessOperations");
	
	AccessKind = AccessKinds.Add();
	AccessKind.Name = "_DemoCompanies";
	AccessKind.Presentation = NStr("ru = 'Демо: Организации';
									|en = 'Demo: Companies';");
	AccessKind.ValuesType   = Type("CatalogRef._DemoCompanies");
	
	AccessKind = AccessKinds.Add();
	AccessKind.Name = "_DemoDepartments";
	AccessKind.Presentation = NStr("ru = 'Демо: Подразделения';
									|en = 'Demo: Departments';");
	AccessKind.ValuesType   = Type("CatalogRef._DemoDepartments");
	
EndProcedure

// See AccessManagementOverridable.OnFillSuppliedAccessGroupProfiles.
Procedure OnFillSuppliedAccessGroupProfiles(ProfilesDetails, ParametersOfUpdate) Export
	
	FillUserProfile(ProfilesDetails);
	FillManagerProfile(ProfilesDetails);
	FillWarehouseSupervisorProfile(ProfilesDetails);
	FillOfficerProfile(ProfilesDetails);
	FillAccountantProfile(ProfilesDetails);
	FillPayrollAndBenefitsOfficerProfile(ProfilesDetails);
	FillAuditorProfile(ProfilesDetails);
	FillPartnerProfile(ProfilesDetails);
	
	// These are additional profiles, which are not used independently for setting up user rights.
	// They are used to augment the main profiles specified above.
	
	FillPersonResponsibleForMasterDataProfile(ProfilesDetails);
	FillPersonResponsibleForProductsProfile(ProfilesDetails);
	FillPersonResponsibleForInteractionsProfile(ProfilesDetails);
	FillPersonResponsibleForUsersListProfile(ProfilesDetails);
	FillPersonResponsibleForExternalUsersListProfile(ProfilesDetails);
	FillPersonResponsibleForAccessGroupsMembersListProfile(ProfilesDetails);
	FillSetUpFilesSynchronizationWithCloudServiceProfile(ProfilesDetails);
	FillPersonResponsibleForPeriodEndClosingDatesProfile(ProfilesDetails);
	PopulateProfileResponsibleForDataImportRestrictionDates(ProfilesDetails);
	FillEmailUsageProfile(ProfilesDetails);
	FillUnpostedDocumentsPrintProfile(ProfilesDetails);
	FillFilesFoldersOperationsProfile(ProfilesDetails);
	FillEditConsentsToPersonalDataProcessingProfile(ProfilesDetails);
	FillViewConsentsToPersonalDataProcessingProfile(ProfilesDetails);
	
	PrintManagement.FillProfileEditPrintForms(ProfilesDetails);
	
EndProcedure

// See AccessManagementOverridable.OnFillAccessRightsDependencies.
Procedure OnFillAccessRightsDependencies(RightsDependencies) Export
	
	// For tasks of business process "Demo: Duty with role-based assignment".
	String = RightsDependencies.Add();
	String.SubordinateTable = Metadata.Tasks.PerformerTask.FullName();
	String.LeadingTable     = Metadata.BusinessProcesses._DemoJobWithRoleAddressing.FullName();
	
	// For attachments of the "Demo: Projects" catalog.
	String = RightsDependencies.Add();
	String.SubordinateTable = Metadata.Catalogs._DemoProjectsAttachedFiles.FullName();
	String.LeadingTable     = Metadata.Catalogs._DemoProjects.FullName();
	
EndProcedure

// See AccessManagementOverridable.OnFillAccessKindUsage.
Procedure OnFillAccessKindUsage(AccessKind, Use) Export
	
	SetPrivilegedMode(True);
	
	If AccessKind = "_DemoProductGroups" Then
		Use = Constants._DemoRestrictAccessByProducts.Get();
		
	ElsIf AccessKind = "_DemoPartnerGroups" Then
		Use = Constants._DemoRestrictAccessByPartners.Get();
		
	ElsIf AccessKind = "_DemoIndividuals" Then
		Use = Constants._DemoRestrictAccessByIndividuals.Get();
	EndIf;
	
EndProcedure

// See AccessManagementOverridable.OnFillMetadataObjectsAccessRestrictionKinds.
Procedure OnFillMetadataObjectsAccessRestrictionKinds(LongDesc) Export
	
	// _DemoBusinessProcessesAndTasks
	LongDesc = LongDesc + "
	|BusinessProcess._DemoJobWithRoleAddressing.Read.Object.BusinessProcess._DemoJobWithRoleAddressing
	|BusinessProcess._DemoJobWithRoleAddressing.Update.Object.BusinessProcess._DemoJobWithRoleAddressing
	|Task.PerformerTask.Read.ExternalUsers
	|Task.PerformerTask.Update.ExternalUsers
	|Task.PerformerTask.Read.Object.BusinessProcess._DemoJobWithRoleAddressing
	|InformationRegister.BusinessProcessesData.Read.Object.BusinessProcess._DemoJobWithRoleAddressing
	|BusinessProcess._DemoJobWithRoleAddressing.Read.ExternalUsers
	|BusinessProcess._DemoJobWithRoleAddressing.Update.ExternalUsers
	|InformationRegister.TaskPerformers.Read.ExternalUsers
	|InformationRegister.TaskPerformers.Read._DemoCompanies
	|InformationRegister.TaskPerformers.Update._DemoCompanies
	|";
	// _DemoCompanies
	LongDesc = LongDesc + "
	|Catalog._DemoCompanies.Read._DemoCompanies
	|Catalog._DemoCompaniesAttachedFiles.Read._DemoCompanies
	|";
	
	// AccountingAudit
	LongDesc = LongDesc + "
	|InformationRegister.AccountingCheckResults.Read._DemoCompanies
	|";
	
	// _DemoAccessManagement
	LongDesc = LongDesc + "
	|Catalog._DemoProductsKinds.Update._DemoProductGroups
	|Catalog._DemoProducts.Update._DemoProductGroups
	|Catalog._DemoProductsAttachedFiles.Update._DemoProductGroups
	|";
	
	// Other demo objects.
	LongDesc = LongDesc + "
	|Catalog._DemoBankAccounts.Read._DemoPartnerGroups
	|Catalog._DemoBankAccounts.Read._DemoCompanies
	|Catalog._DemoBankAccounts.Update._DemoPartnerGroups
	|Catalog._DemoBankAccounts.Update._DemoCompanies
	|Catalog._DemoBankAccounts.Read.ExternalUsers
	|Catalog._DemoPartnersAccessGroups.Read._DemoPartnerGroups
	|Catalog._DemoCounterpartiesContracts.Read._DemoPartnerGroups
	|Catalog._DemoCounterpartiesContracts.Read._DemoCompanies
	|Catalog._DemoCounterpartiesContracts.Update._DemoPartnerGroups
	|Catalog._DemoCounterpartiesContracts.Update._DemoCompanies
	|Catalog._DemoStorageLocations.Read._DemoStorageLocations
	|Catalog._DemoCashAccounts.Update._DemoCompanies
	|Catalog._DemoCashRegisters.Update._DemoCompanies
	|Catalog._DemoPartnersContactPersons.Read.ExternalUsers
	|Catalog._DemoPartnersContactPersons.Read._DemoPartnerGroups
	|Catalog._DemoPartnersContactPersons.Update._DemoPartnerGroups
	|Catalog._DemoCounterparties.Read._DemoPartnerGroups
	|Catalog._DemoCounterparties.Update._DemoPartnerGroups
	|Catalog._DemoCounterparties.Read.ExternalUsers
	|Catalog._DemoPartners.Read._DemoPartnerGroups
	|Catalog._DemoPartners.Read.ExternalUsers
	|Catalog._DemoPartners.Update._DemoPartnerGroups
	|Catalog._DemoDepartments.Read._DemoDepartments
	|Catalog._DemoProjects.Read._DemoCompanies
	|Catalog._DemoProjects.Update._DemoCompanies
	|Catalog._DemoProjects.Update.Users
	|Catalog._DemoProjectsAttachedFiles.Read.Object.Catalog._DemoProjects
	|Catalog._DemoProjectsAttachedFiles.Update.Object.Catalog._DemoProjects
	|Catalog._DemoCustomerProformaInvoiceAttachedFiles.Read._DemoPartnerGroups
	|Catalog._DemoCustomerProformaInvoiceAttachedFiles.Read._DemoCompanies
	|Catalog._DemoCustomerProformaInvoiceAttachedFiles.Update._DemoPartnerGroups
	|Catalog._DemoCustomerProformaInvoiceAttachedFiles.Update._DemoCompanies
	|Catalog._DemoCustomerProformaInvoiceAttachedFiles.Read.ExternalUsers
	|Catalog._DemoCustomerProformaInvoiceAttachedFiles.Update.ExternalUsers
	|Document._DemoPayrollAccrual.Read.Object.Document._DemoPayrollAccrual
	|Document._DemoPayrollAccrual.Update.Object.Document._DemoPayrollAccrual
	|Document._DemoSalesOrder.Read._DemoCompanies
	|Document._DemoSalesOrder.Read._DemoPartnerGroups
	|Document._DemoSalesOrder.Update._DemoCompanies
	|Document._DemoSalesOrder.Update._DemoPartnerGroups
	|Document._DemoReceivedGoodsRecording.Read._DemoStorageLocations
	|Document._DemoReceivedGoodsRecording.Read._DemoCompanies
	|Document._DemoReceivedGoodsRecording.Update._DemoStorageLocations
	|Document._DemoReceivedGoodsRecording.Update._DemoCompanies
	|Document._DemoReceivedGoodsRecording.Update.Users
	|Document._DemoInventoryTransfer.Read._DemoStorageLocations
	|Document._DemoInventoryTransfer.Read._DemoCompanies
	|Document._DemoInventoryTransfer.Update._DemoStorageLocations
	|Document._DemoInventoryTransfer.Update._DemoCompanies
	|Document._DemoInventoryTransfer.Update.Users
	|Document._DemoForwarderInstruction.Read._DemoPartnerGroups
	|Document._DemoForwarderInstruction.Read._DemoStorageLocations
	|Document._DemoForwarderInstruction.Read._DemoIndividuals
	|Document._DemoForwarderInstruction.Update._DemoPartnerGroups
	|Document._DemoForwarderInstruction.Update._DemoStorageLocations
	|Document._DemoForwarderInstruction.Update._DemoIndividuals
	|Document._DemoGoodsReceipt.Read._DemoPartnerGroups
	|Document._DemoGoodsReceipt.Read._DemoStorageLocations
	|Document._DemoGoodsReceipt.Read._DemoCompanies
	|Document._DemoGoodsReceipt.Update._DemoPartnerGroups
	|Document._DemoGoodsReceipt.Update._DemoStorageLocations
	|Document._DemoGoodsReceipt.Update._DemoCompanies
	|Document._DemoCashVoucher.Read._DemoCompanies
	|Document._DemoCashVoucher.Read._DemoCashAccounts
	|Document._DemoCashVoucher.Read._DemoBusinessOperations
	|Document._DemoCashVoucher.Update._DemoCompanies
	|Document._DemoCashVoucher.Update._DemoCashAccounts
	|Document._DemoCashVoucher.Update._DemoBusinessOperations
	|Document._DemoGoodsSales.Read._DemoPartnerGroups
	|Document._DemoGoodsSales.Read._DemoStorageLocations
	|Document._DemoGoodsSales.Read._DemoCompanies
	|Document._DemoGoodsSales.Read._DemoDepartments
	|Document._DemoGoodsSales.Update._DemoPartnerGroups
	|Document._DemoGoodsSales.Update._DemoStorageLocations
	|Document._DemoGoodsSales.Update._DemoCompanies
	|Document._DemoGoodsSales.Update._DemoDepartments
	|Document._DemoGoodsWriteOff.Read._DemoStorageLocations
	|Document._DemoGoodsWriteOff.Read._DemoCompanies
	|Document._DemoGoodsWriteOff.Update._DemoStorageLocations
	|Document._DemoGoodsWriteOff.Update._DemoCompanies
	|Document._DemoGoodsWriteOff.Update.Users
	|Document._DemoCustomerProformaInvoice.Read._DemoPartnerGroups
	|Document._DemoCustomerProformaInvoice.Read._DemoCompanies
	|Document._DemoCustomerProformaInvoice.Update._DemoPartnerGroups
	|Document._DemoCustomerProformaInvoice.Update._DemoCompanies
	|Document._DemoCustomerProformaInvoice.Read.ExternalUsers
	|Document._DemoTaxInvoiceReceived.Read._DemoPartnerGroups
	|Document._DemoTaxInvoiceReceived.Update._DemoPartnerGroups
	|DocumentJournal._DemoWarehouseDocuments.Read.Object.Document._DemoReceivedGoodsRecording
	|DocumentJournal._DemoWarehouseDocuments.Read.Object.Document._DemoInventoryTransfer
	|DocumentJournal._DemoWarehouseDocuments.Read.Object.Document._DemoGoodsWriteOff
	|InformationRegister._DemoImportedInpaymentsFromBusinessEntities.Read._DemoPartnerGroups
	|InformationRegister._DemoImportedInpaymentsFromBusinessEntities.Update._DemoPartnerGroups
	|InformationRegister._DemoCompaniesEmployees.Read._DemoIndividuals
	|InformationRegister._DemoCompaniesEmployees.Read._DemoCompanies
	|InformationRegister._DemoCompaniesEmployees.Update._DemoIndividuals
	|InformationRegister._DemoCompaniesEmployees.Update._DemoCompanies
	|InformationRegister._DemoWarehouseDocumentsRegister.Read._DemoStorageLocations
	|InformationRegister._DemoWarehouseDocumentsRegister.Read._DemoCompanies
	|InformationRegister._DemoProductsPrices.Update._DemoProductGroups
	|AccumulationRegister._DemoGoodsBalancesInStorageLocations.Read._DemoStorageLocations
	|AccumulationRegister._DemoGoodsBalancesInStorageLocations.Read._DemoCompanies
	|AccumulationRegister._DemoGoodsBalancesInStorageLocations.Read._DemoProductGroups
	|";
	
EndProcedure

// See AccessManagementOverridable.OnChangeAccessValuesSets.
Procedure OnChangeAccessValuesSets(Ref, RefsToDependentObjects) Export
	
	If TypeOf(Ref) = Type("DocumentRef._DemoSalesOrder") Then
		
		// Dependent object types:
		
		//  BusinessProcess._DemoJobWithRoleAddressing
		Query = New Query(
		"SELECT
		|	_DemoJobWithRoleAddressing.Ref
		|FROM
		|	BusinessProcess._DemoJobWithRoleAddressing AS _DemoJobWithRoleAddressing
		|WHERE
		|	_DemoJobWithRoleAddressing.SubjectOf = &SubjectOf");
		Query.SetParameter("SubjectOf", Ref);
		RefsToDependentObjects = Query.Execute().Unload().UnloadColumn("Ref");
	EndIf;
	
EndProcedure

// See AccessManagementOverridable.OnFillListsWithAccessRestriction.
Procedure OnFillListsWithAccessRestriction(Lists) Export
	
	Lists.Insert(Metadata.Catalogs._DemoBankAccounts, True);
	Lists.Insert(Metadata.Catalogs._DemoProductsKinds, True);
	Lists.Insert(Metadata.Catalogs._DemoPartnersAccessGroups, True);
	Lists.Insert(Metadata.Catalogs._DemoCounterpartiesContracts, True);
	Lists.Insert(Metadata.Catalogs._DemoCashAccounts, True);
	Lists.Insert(Metadata.Catalogs._DemoCashRegisters, True);
	Lists.Insert(Metadata.Catalogs._DemoPartnersContactPersons, True);
	Lists.Insert(Metadata.Catalogs._DemoCounterparties, True);
	Lists.Insert(Metadata.Catalogs._DemoStorageLocations, True);
	Lists.Insert(Metadata.Catalogs._DemoProducts, True);
	Lists.Insert(Metadata.Catalogs._DemoProductsAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs._DemoCompanies, True);
	Lists.Insert(Metadata.Catalogs._DemoCompaniesAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs._DemoPartners, True);
	Lists.Insert(Metadata.Catalogs._DemoDepartments, True);
	Lists.Insert(Metadata.Catalogs._DemoProjects, True);
	Lists.Insert(Metadata.Catalogs._DemoProjectsAttachedFiles, True);
	Lists.Insert(Metadata.Catalogs._DemoCustomerProformaInvoiceAttachedFiles, True);
	Lists.Insert(Metadata.Documents._DemoSalesOrder, True);
	Lists.Insert(Metadata.Documents._DemoPayrollAccrual, True);
	Lists.Insert(Metadata.Documents._DemoReceivedGoodsRecording, True);
	Lists.Insert(Metadata.Documents._DemoInventoryTransfer, True);
	Lists.Insert(Metadata.Documents._DemoForwarderInstruction, True);
	Lists.Insert(Metadata.Documents._DemoGoodsReceipt, True);
	Lists.Insert(Metadata.Documents._DemoCashVoucher, True);
	Lists.Insert(Metadata.Documents._DemoGoodsSales, True);
	Lists.Insert(Metadata.Documents._DemoGoodsWriteOff, True);
	Lists.Insert(Metadata.Documents._DemoCustomerProformaInvoice, True);
	Lists.Insert(Metadata.Documents._DemoTaxInvoiceReceived, True);
	Lists.Insert(Metadata.DocumentJournals._DemoWarehouseDocuments, True);
	Lists.Insert(Metadata.InformationRegisters._DemoImportedInpaymentsFromBusinessEntities, True);
	Lists.Insert(Metadata.InformationRegisters._DemoCompaniesEmployees, True);
	Lists.Insert(Metadata.InformationRegisters._DemoWarehouseDocumentsRegister, True);
	Lists.Insert(Metadata.InformationRegisters._DemoProductsPrices, True);
	Lists.Insert(Metadata.AccumulationRegisters._DemoGoodsBalancesInStorageLocations, True);
	Lists.Insert(Metadata.BusinessProcesses._DemoJobWithRoleAddressing, True);
	
	// Override restriction of lists in the BusinessProcesses subsystem.
	Lists.Insert(Metadata.InformationRegisters.TaskPerformers, False);
	
	// Override restriction of lists in the Interactions subsystem.
	Lists.Insert(Metadata.Documents.Meeting, False);
	Lists.Insert(Metadata.Documents.PlannedInteraction, False);
	Lists.Insert(Metadata.Documents.SMSMessage, False);
	Lists.Insert(Metadata.Documents.PhoneCall, False);
	Lists.Insert(Metadata.Documents.IncomingEmail, False);
	Lists.Insert(Metadata.Documents.OutgoingEmail, False);
	
	// Override restriction of lists in the AccountingAudit subsystem.
	Lists.Insert(Metadata.InformationRegisters.AccountingCheckResults, False);
	
EndProcedure

// See AccessManagementOverridable.OnFillAccessRestriction.
Procedure OnFillAccessRestriction(List, Restriction) Export
	
	If List = Metadata.InformationRegisters.TaskPerformers Then
		
		// The types of the attributes "MainAddressingObject" and "AdditionalAddressingObject":
		//  CatalogRef._DemoDepartments,
		//  CatalogRef._DemoCompanies,
		//  CatalogRef._DemoProjects.
		
		Restriction.Text =
		"AllowReadUpdate
		|WHERE
		|	ValueAllowed(MainAddressingObject ONLY Catalog._DemoCompanies)
		|	OR ValueAllowed(AdditionalAddressingObject ONLY Catalog._DemoCompanies)
		|	OR (VALUETYPE(MainAddressingObject) <> TYPE(Catalog._DemoCompanies) AND MainAddressingObject <> UNDEFINED)
		|	OR (VALUETYPE(AdditionalAddressingObject) <> TYPE(Catalog._DemoCompanies) AND AdditionalAddressingObject <> UNDEFINED)";
		
		Restriction.TextForExternalUsers1 =
		"AllowReadUpdate
		|WHERE
		|	ValueAllowed(CAST(Performer AS Catalog.ExternalUsers))";
		
	ElsIf List = Metadata.Documents.Meeting Then
		OnFillAccessRestrictionForMeeting(Restriction);
		
	ElsIf List = Metadata.Documents.PlannedInteraction Then
		OnFillAccessRestrictionForScheduledInteraction(Restriction);
		
	ElsIf List = Metadata.Documents.SMSMessage Then
		OnFillAccessRestrictionForSMSMessage(Restriction);
		
	ElsIf List = Metadata.Documents.PhoneCall Then
		OnFillAccessRestrictionForPhoneCall(Restriction);
		
	ElsIf List = Metadata.Documents.IncomingEmail Then
		OnFillAccessRestrictionForIncomingEmail(Restriction);
		
	ElsIf List = Metadata.Documents.OutgoingEmail Then
		OnFillAccessRestrictionForOutgoingEmail(Restriction);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region MessageTemplates

// See MessageTemplatesOverridable.OnDefineSettings
Procedure OnDefineMessageTemplatesSettings(Settings) Export
	
	Settings.UseArbitraryParameters = True;
	Settings.DCSParametersValues.Insert("SalutationMale", NStr("ru = 'Уважаемый';
																		|en = 'Dear';"));
	Settings.DCSParametersValues.Insert("SalutationFemale", NStr("ru = 'Уважаемая';
																		|en = 'Dear';"));
	Settings.ExtendedRecipientsList = True;
	
	// Define templates.
	SubjectOf = Settings.TemplatesSubjects.Add();
	SubjectOf.Name = "CustomerNotificationChangeOrder";
	SubjectOf.Presentation = NStr("ru = 'Оповещение клиента ""Изменение заказа""';
								|en = '""Order Update"" notification';");
	SubjectOf.Template = "MessagesTemplateData";
	SubjectOf = Settings.TemplatesSubjects.Find("CustomerNotificationChangeOrder", "Name");
	SubjectOf.DCSParametersValues.Insert("SalutationGenderUnknown", NStr("ru = 'Уважаемый(ая)';
																			|en = 'Dear';"));
	
	SubjectOf = Settings.TemplatesSubjects.Find(Metadata.Documents._DemoSalesOrder.FullName(), "Name");
	SubjectOf.DCSParametersValues.Insert("SalutationGenderUnknown", NStr("ru = 'Уважаемый(ая)';
																			|en = 'Dear';"));
	
	// Define common attributes for all templates
	NewAttribute = Settings.CommonAttributes.Rows.Add();
	NewAttribute.Name = "ReplyTo";
	NewAttribute.Presentation = NStr("ru = 'Обратный адрес';
										|en = 'Reply-to address';");
	NewAttribute.Type = Type("String");
	
	NewAttribute = Settings.CommonAttributes.Rows.Add();
	NewAttribute.Name = "MainCompany";
	NewAttribute.Presentation = NStr("ru = 'Основная организация';
										|en = 'Parent company';");
	NewAttribute.Type = Type("CatalogRef._DemoCompanies");
	
EndProcedure

// See MessageTemplatesOverridable.OnPrepareMessageTemplate
Procedure OnPrepareMessageTemplate(Attributes, Attachments, TemplateAssignment, AdditionalParameters) Export
	
	If TemplateAssignment = "Document._DemoCustomerProformaInvoice" Then
		AdditionalParameters.ExpandRefAttributes = False;
	EndIf;
	
	If TemplateAssignment = "Document._DemoCustomerProformaInvoice"
		Or TemplateAssignment = "Document._DemoSalesOrder" Then
		If AdditionalParameters.TemplateType = "MailMessage" Then
			NewAttribute = Attributes.Add();
			NewAttribute.Name = "YandexCheckoutPayButton";
			NewAttribute.Presentation = NStr("ru = 'Кнопка для оплаты Яндекс.Касса';
												|en = 'Yandex.Checkout button';");
			If AdditionalParameters.EmailFormat1 = Enums.EmailEditingMethods.HTML Then
				ButtonPicture = Attachments.Add();
				ButtonPicture.Id = "CheckoutPayButtonPicture";
				ButtonPicture.Name = "CheckoutPayButtonPicture";
				ButtonPicture.Presentation = NStr("ru = 'Кнопка для оплаты Яндекс.Касса';
													|en = 'Yandex.Checkout button';");
				ButtonPicture.FileType = "jpg";
				ButtonPicture.Attribute = "YandexCheckoutPayButton";
			EndIf;
		EndIf;
	EndIf;
	
	If TemplateAssignment = "CustomerNotificationChangeOrder" Then
		MessageTemplates.GenerateAttributesListByDCS(Attributes, 
			Documents._DemoSalesOrder.GetTemplate("MessagesTemplateData"));
		
		Attribute = Attributes.Find("CustomerNotificationChangeOrder.Date");
		Attribute.Format = "DLF=D";
	EndIf;
	
EndProcedure

// See MessageTemplatesOverridable.OnCreateMessage
Procedure OnCreateMessage(Message, TemplateAssignment, MessageSubject, TemplateParameters) Export
	
	If Message.CommonAttributesValues["ReplyTo"] <> Undefined Then
		Message.CommonAttributesValues["ReplyTo"] = "admin@admin.org";
	EndIf;
	
	If Message.CommonAttributesValues["MainCompany"] <> Undefined Then
		MainCompany = Constants._DemoMainCompany.Get();
		Message.CommonAttributesValues["MainCompany"] = MainCompany.Description;
	EndIf;
	
	If TemplateParameters.TemplateType = "MailMessage"
		And (TemplateAssignment = "Document._DemoCustomerProformaInvoice"
		Or TemplateAssignment = "Document._DemoSalesOrder") Then
			DocumentNumber = Common.ObjectAttributeValue(MessageSubject, "Number");
			Ref = "www.oplata.1c?order=" + XMLString(DocumentNumber);
			If TemplateParameters.EmailFormat1 = Enums.EmailEditingMethods.HTML Then
				If Message.AttributesValues["YandexCheckoutPayButton"] <> Undefined Then 
					If Message.Attachments["YandexCheckoutPayButton"] = Undefined Then
						HTMLButtonText = StringFunctionsClientServer.SubstituteParametersToString(
							"<a href='%1'><img src=""cid:YandexCheckoutPayButton"">%2</a>", 
								Ref,  NStr("ru = 'Оплатить онлайн';
												|en = 'Pay online';"));
						PictureAddress = PutToTempStorage(PictureLib.DialogInformation.GetBinaryData());
						Message.Attachments["YandexCheckoutPayButton"] = PictureAddress;
					Else
						HTMLButtonText = "<a href='" + Ref + "'><img src=""cid:YandexCheckoutPayButton""></a>";
					EndIf;
					Message.AttributesValues["YandexCheckoutPayButton"] = HTMLButtonText;
				EndIf;
			Else
				Message.AttributesValues["YandexCheckoutPayButton"] = NStr("ru = 'Оплатить счет:';
																					|en = 'Pay the bill:';") + Chars.LF + Ref;
			EndIf;
		EndIf;
	
	If TemplateAssignment = "CustomerNotificationChangeOrder" Then
		MessageTemplates.FillAttributesByDCS(Message.AttributesValues, MessageSubject, TemplateParameters);
		If TypeOf(Message.AttributesValues[TemplateAssignment]) = Type("Map") Then
			DocumentAmount = Common.ObjectAttributeValue(MessageSubject, "DocumentAmount");
			Message.AttributesValues[TemplateAssignment]["DocumentAmount"] = DocumentAmount;
		EndIf;
	EndIf;
	
EndProcedure

// See MessageTemplatesOverridable.OnFillRecipientsEmailsInMessage
Procedure OnFillRecipientsEmailsInMessage(EmailRecipients, TemplateAssignment, MessageSubject) Export
	
	If TemplateAssignment = "CustomerNotificationChangeOrder" Then
		SubjectOf = ?(TypeOf(MessageSubject) = Type("Structure"), MessageSubject.SubjectOf, MessageSubject);
		RecipientsList = CommonClientServer.EmailsFromString(SubjectOf.EmailString);
		For Each Recipient In RecipientsList Do
			If IsBlankString(Recipient.ErrorDescription) Then
				NewRecipient               = EmailRecipients.Add();
				NewRecipient.Address         = Recipient.Address;
				NewRecipient.Presentation = Recipient.Alias;
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion

#Region DigitalSignature


// See DigitalSignatureOverridable.OnCreateFormCertificateCheck
Procedure OnCreateFormCertificateCheck(Certificate, AdditionalChecks, AdditionalChecksParameters,
	StandardChecks, EnterPassword) Export
	
	NewCheck = AdditionalChecks.Add();
	NewCheck.Name = "TestOperationConnection";
	NewCheck.Presentation = NStr("ru = 'Демо: Дополнительная проверка';
										|en = 'Demo: Additional check';");
	NewCheck.ToolTip     = NStr("ru = 'Демонстрирует прикладную проверку сертификата электронной подписи.';
										|en = 'Showcase of the applied digital signature certificate check.';");
	
EndProcedure

// See DigitalSignatureOverridable.OnAdditionalCertificateCheck.
Procedure OnAdditionalCertificateCheck(Parameters) Export
	
	If Parameters.Validation = "TestOperationConnection" Then
		Parameters.ErrorDescription = "";
	EndIf;
	
EndProcedure

#EndRegion


#EndRegion

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Implementation of the event OnFillSuppliedAccessGroupsProfiles.

// Main profiles.

Procedure FillUserProfile(Val ProfilesDetails)
	
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "_DemoUser";
	ProfileDetails.Id = "09e56dbf-90a0-11de-862c-001d600d9ad2";
	ProfileDetails.Description  = NStr("ru = 'Пользователь';
										|en = 'User';", Common.DefaultLanguageCode());
	ProfileDetails.LongDesc =
		NStr("ru = 'Общие разрешенные действия для большинства пользователей.
		           |Как правило, это права на просмотр данных информационной системы.';
					|en = 'Common actions permitted for most users.
					|As a rule, these are rights to view infobase data.';");
	
	// Use 1C:Enterprise.
	ProfileDetails.Roles.Add("StartWebClient");
	ProfileDetails.Roles.Add("StartThickClient");
	ProfileDetails.Roles.Add("StartThinClient");
	ProfileDetails.Roles.Add("StartMobileClient");
	ProfileDetails.Roles.Add("OutputToPrinterFileClipboard");
	ProfileDetails.Roles.Add("SaveUserData");
	
	// Use the application.
	AddRolesForAllCommandInterfaceSections(ProfileDetails);
	ProfileDetails.Roles.Add("BasicAccessSSL");
	ProfileDetails.Roles.Add("BasicAccessCTL");
	ProfileDetails.Roles.Add("BasicAccessOUS");
	ProfileDetails.Roles.Add("ViewApplicationChangeLog");
	ProfileDetails.Roles.Add("PrintFormsEdit");
	ProfileDetails.Roles.Add("AddEditFoldersAndFiles");
	ProfileDetails.Roles.Add("_DemoBasicAccessSSL");
	ProfileDetails.Roles.Add("_DemoMySettings");
	
	// Use MasterData.
	ProfileDetails.Roles.Add("ReadWorkSchedules");
	ProfileDetails.Roles.Add("ReadCurrencyRates");
	ProfileDetails.Roles.Add("_DemoReadMasterData");
	
	// Standard features.
	ProfileDetails.Roles.Add("AddEditPersonalReportsOptions");
	ProfileDetails.Roles.Add("AddEditPersonalMessageTemplates");
	ProfileDetails.Roles.Add("ReadAdditionalReportsAndDataProcessors");
	ProfileDetails.Roles.Add("ViewRelatedDocuments");
	ProfileDetails.Roles.Add("AddEditDigitalSignatureAndEncryptionKeyCertificates");
	ProfileDetails.Roles.Add("AddEditDigitalSignatures");
	ProfileDetails.Roles.Add("EncryptAndDecryptData");
	ProfileDetails.Roles.Add("UseDigitalSignatureInSaaS");
	ProfileDetails.Roles.Add("UseCurrentToDosProcessor");
	ProfileDetails.Roles.Add("ReadPeriodEndClosingDates");
	
	// Basic profile features.
	ProfileDetails.Roles.Add("AddEditNotes");
	ProfileDetails.Roles.Add("_DemoUseSourceDocumentOriginalsJournalDataProcessor");
	ProfileDetails.Roles.Add("AddEditNotifications");
	ProfileDetails.Roles.Add("_DemoReadProjects");
	ProfileDetails.Roles.Add("AddEditJobs");
	ProfileDetails.Roles.Add("_DemoAddEditJobsWithRoleAddressing");
	ProfileDetails.Roles.Add("EditCompleteTask");
	
	// Surveys.
	ProfileDetails.Roles.Add("AddEditQuestionnaireQuestionsAnswers");
	ProfileDetails.Roles.Add("ReadQuestionnaireQuestionAnswers");
	
	// Profile access restriction kinds.
	ProfileDetails.AccessKinds.Add("_DemoStorageLocations");
	ProfileDetails.AccessKinds.Add("_DemoCompanies");
	ProfileDetails.AccessKinds.Add("_DemoDepartments", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("_DemoPartnerGroups");
	ProfileDetails.AccessKinds.Add("_DemoProductGroups");
	ProfileDetails.AccessKinds.Add("AdditionalReportsAndDataProcessors", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Users", "Predefined");
	
	// Use online support.
	ProfileDetails.Roles.Add("CanEnableOnlineSupport");
	
	// Use the "Data integrity" subsystem.
	ProfileDetails.Roles.Add("ReadAccountingCheckResults");
	
	// Use the "Source document tracking" subsystem.
	SourceDocumentsOriginalsRecording.SupplementProfileWithRoleForDocumentsOriginalsStatesChange(ProfileDetails);
	
	
	ProfilesDetails.Add(ProfileDetails);
	
	// Check if adding role twice is acceptable.
	ProfileDetails.Roles.Add("BasicAccessSSL");
	
EndProcedure

Procedure FillManagerProfile(Val ProfilesDetails)
	
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "_DemoManager";
	ProfileDetails.Id = "c7e34f11-9890-11df-b54f-e0cb4ed5f655";
	ProfileDetails.Description  = NStr("ru = 'Менеджер';
										|en = 'Manager';", Common.DefaultLanguageCode());
	ProfileDetails.LongDesc =
		NStr("ru = 'Предназначен для настройки групп доступа, демонстрирующих
		           |работу пользователей по вводу и изменению данных различных подсистем в разрезе различных
		           |видов доступа. В частности:
		           |- проведение и анализ результатов опросов (подсистема ""Анкетирование"");
		           |- ведение дополнительных сведений (подсистема ""Свойства"");
		           |- редактирование проектов и их присоединенных файлов (подсистема ""Присоединенные файлы"").
		           |
		           |Кроме того, в отличие от профилей ""Руководитель"" и ""Бухгалтер"", менеджерам вообще
		           |не доступны документы ""Демо: Расходный кассовый ордер"".';
					|en = 'It is designed to set up access groups that demonstrate
					|user operations on entering and changing data of different subsystems broken down by
					|various access kinds. In particular:
					|- post and analyze survey results (the ""Surveys"" subsystem),
					|- keep additional info (the ""Properties"" subsystem),
					|- edit projects and their attachments (the ""Attachments"" subsystem).
					|
					|Moreover, unlike the ""Officer"" and ""Accountant"" profiles, managers
					|do not have access to the ""Demo: Outgoing payment — Cash account"" documents.';");
	
	// Use 1C:Enterprise.
	ProfileDetails.Roles.Add("StartWebClient");
	ProfileDetails.Roles.Add("StartThickClient");
	ProfileDetails.Roles.Add("StartThinClient");
	ProfileDetails.Roles.Add("StartMobileClient");
	ProfileDetails.Roles.Add("OutputToPrinterFileClipboard");
	ProfileDetails.Roles.Add("SaveUserData");
	
	// Use the application.
	AddRolesForAllCommandInterfaceSections(ProfileDetails);
	ProfileDetails.Roles.Add("Subsystem_DemoSurvey");
	ProfileDetails.Roles.Add("BasicAccessSSL");
	ProfileDetails.Roles.Add("BasicAccessCTL");
	ProfileDetails.Roles.Add("BasicAccessOUS");
	ProfileDetails.Roles.Add("ViewApplicationChangeLog");
	ProfileDetails.Roles.Add("PrintFormsEdit");
	ProfileDetails.Roles.Add("AddEditFoldersAndFiles");
	ProfileDetails.Roles.Add("_DemoBasicAccessSSL");
	ProfileDetails.Roles.Add("_DemoMySettings");
	
	// Use MasterData.
	ProfileDetails.Roles.Add("ReadWorkSchedules");
	ProfileDetails.Roles.Add("ReadCurrencyRates");
	ProfileDetails.Roles.Add("_DemoReadMasterData");
	
	// Standard features.
	ProfileDetails.Roles.Add("AddEditPersonalReportsOptions");
	ProfileDetails.Roles.Add("AddEditPersonalMessageTemplates");
	ProfileDetails.Roles.Add("ViewRelatedDocuments");
	ProfileDetails.Roles.Add("AddEditDigitalSignatureAndEncryptionKeyCertificates");
	ProfileDetails.Roles.Add("AddEditDigitalSignatures");
	ProfileDetails.Roles.Add("EncryptAndDecryptData");
	ProfileDetails.Roles.Add("UseDigitalSignatureInSaaS");
	ProfileDetails.Roles.Add("EditAdditionalInfo");
	ProfileDetails.Roles.Add("UseCurrentToDosProcessor");
	ProfileDetails.Roles.Add("ReadPeriodEndClosingDates");
	
	// Basic profile features.
	ProfileDetails.Roles.Add("_DemoAddEditCustomerDocuments");
	ProfileDetails.Roles.Add("_DemoAddEditProjects");
	ProfileDetails.Roles.Add("_DemoUseSourceDocumentOriginalsJournalDataProcessor");
	ProfileDetails.Roles.Add("_DemoReadLeaves");
	ProfileDetails.Roles.Add("_DemoReadWarehouseDocuments");
	ProfileDetails.Roles.Add("_DemoPrintProformaInvoice");
	ProfileDetails.Roles.Add("AddEditPolls");
	ProfileDetails.Roles.Add("AddEditQuestionnairesTemplates");
	ProfileDetails.Roles.Add("ReadQuestionnaireQuestionAnswers");
	
	// Use the "Data integrity" subsystem.
	ProfileDetails.Roles.Add("ReadAccountingCheckResults");
	
	// Profile access restriction kinds.
	ProfileDetails.AccessKinds.Add("_DemoStorageLocations", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("_DemoCompanies");
	ProfileDetails.AccessKinds.Add("_DemoDepartments", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("_DemoPartnerGroups");
	ProfileDetails.AccessKinds.Add("_DemoProductGroups");
	ProfileDetails.AccessKinds.Add("Users", "Predefined");
	ProfileDetails.AccessKinds.Add("AdditionalInfo", "AllDeniedByDefault");
		
	SourceDocumentsOriginalsRecording.SupplementProfileWithRoleForDocumentsOriginalsStatesChange(ProfileDetails);
		
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

Procedure FillWarehouseSupervisorProfile(Val ProfilesDetails)
	
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "_DemoWarehouseManager";
	ProfileDetails.Id = "17a7b55d-4f89-11e4-9e14-005056c00008";
	ProfileDetails.Description  = NStr("ru = 'Кладовщик';
										|en = 'Warehouse supervisor';", Common.DefaultLanguageCode());
	ProfileDetails.LongDesc =
		NStr("ru = 'Предназначен для настройки групп доступа, демонстрирующих
		           |работу пользователей по вводу и изменению данных различных подсистем в разрезе различных
		           |видов доступа. В частности:
		           |- ведение дополнительных сведений (подсистема ""Свойства"");
		           |- редактирование проектов и их присоединенных файлов (подсистема ""Присоединенные файлы"").
		           |
		           |Кроме того, в отличие от профилей ""Руководитель"" и ""Бухгалтер"", кладовщикам вообще
		           |не доступны документы ""Демо: Расходный кассовый ордер"".';
					|en = 'It is designed to set up access groups that demonstrate
					|user operations on entering and changing data of different subsystems broken down by
					|various access kinds. In particular:
					|- keep additional info (the ""Properties"" subsystem),
					|- edit projects and their attachments (the ""Attachments"" subsystem).
					|
					|Moreover, unlike the ""Officer"" and ""Accountant"" profiles, warehouse supervisors
					|do not have access to the ""Demo: Outgoing payment — Cash account"" documents.';");
	
	// Use 1C:Enterprise.
	ProfileDetails.Roles.Add("StartWebClient");
	ProfileDetails.Roles.Add("StartThickClient");
	ProfileDetails.Roles.Add("StartThinClient");
	ProfileDetails.Roles.Add("StartMobileClient");
	ProfileDetails.Roles.Add("OutputToPrinterFileClipboard");
	ProfileDetails.Roles.Add("SaveUserData");
	
	// Use the application.
	AddRolesForAllCommandInterfaceSections(ProfileDetails);
	ProfileDetails.Roles.Add("BasicAccessSSL");
	ProfileDetails.Roles.Add("BasicAccessCTL");
	ProfileDetails.Roles.Add("BasicAccessOUS");
	ProfileDetails.Roles.Add("ViewApplicationChangeLog");
	ProfileDetails.Roles.Add("PrintFormsEdit");
	ProfileDetails.Roles.Add("AddEditFoldersAndFiles");
	ProfileDetails.Roles.Add("_DemoBasicAccessSSL");
	ProfileDetails.Roles.Add("_DemoMySettings");
	
	// Use MasterData.
	ProfileDetails.Roles.Add("ReadWorkSchedules");
	ProfileDetails.Roles.Add("ReadCurrencyRates");
	ProfileDetails.Roles.Add("_DemoReadMasterData");
	
	// Standard features.
	ProfileDetails.Roles.Add("AddEditPersonalReportsOptions");
	ProfileDetails.Roles.Add("AddEditPersonalMessageTemplates");
	ProfileDetails.Roles.Add("ViewRelatedDocuments");
	ProfileDetails.Roles.Add("EditAdditionalInfo");
	ProfileDetails.Roles.Add("UseCurrentToDosProcessor");
	ProfileDetails.Roles.Add("ReadPeriodEndClosingDates");
	
	// Basic profile features.
	ProfileDetails.Roles.Add("_DemoAddEditWarehouseDocuments");
	ProfileDetails.Roles.Add("_DemoAddEditInventoryTransfers");
	ProfileDetails.Roles.Add("_DemoReadCustomersDocuments");
	
	// Use the "Data integrity" subsystem.
	ProfileDetails.Roles.Add("ReadAccountingCheckResults");
	
	// Profile access restriction kinds.
	ProfileDetails.AccessKinds.Add("_DemoStorageLocations", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("_DemoPartnerGroups", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("_DemoCompanies", "AllDeniedByDefault");
	ProfileDetails.AccessKinds.Add("_DemoDepartments", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Users", "Predefined");
	ProfileDetails.AccessKinds.Add("_DemoProductGroups", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("AdditionalInfo", "AllDeniedByDefault");
	
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

Procedure FillOfficerProfile(Val ProfilesDetails)
	
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "_DemoOfficer";
	ProfileDetails.Id = "75fa0ecb-98aa-11df-b54f-e0cb4ed5f655";
	ProfileDetails.Description  = NStr("ru = 'Руководитель';
										|en = 'Senior manager';", Common.DefaultLanguageCode());
	ProfileDetails.LongDesc =
		NStr("ru = 'Предназначен для создания групп доступа, демонстрирующих
		           |использование предустановленных видов доступа. Например, в отличие от профиля ""Бухгалтер""
		           |руководителю разрешено редактировать документы ""Демо: Расходный кассовый ордер"" с типом 
		           |хозяйственной операции - ""Выдача зарплаты"", а персональные данные физических лиц - только просматривать.';
					|en = 'It is designed to create access groups that demonstrate
					|the use of preset access kinds. For example, unlike the ""Accountant"" profile
					|, an officer is allowed to edit the ""Demo: Outgoing payment — Cash account"" documents with the ""Salary payment"" 
					|business transaction type, but not allowed to edit individual personal data, only view it.';");
	
	// Use 1C:Enterprise.
	ProfileDetails.Roles.Add("StartWebClient");
	ProfileDetails.Roles.Add("StartThickClient");
	ProfileDetails.Roles.Add("StartThinClient");
	ProfileDetails.Roles.Add("StartMobileClient");
	ProfileDetails.Roles.Add("OutputToPrinterFileClipboard");
	ProfileDetails.Roles.Add("SaveUserData");
	ProfileDetails.Roles.Add("ViewEventLog");
	
	// Use the application.
	AddRolesForAllCommandInterfaceSections(ProfileDetails);
	ProfileDetails.Roles.Add("Subsystem_DemoSurvey");
	ProfileDetails.Roles.Add("BasicAccessSSL");
	ProfileDetails.Roles.Add("BasicAccessCTL");
	ProfileDetails.Roles.Add("BasicAccessOUS");
	ProfileDetails.Roles.Add("ViewApplicationChangeLog");
	ProfileDetails.Roles.Add("PrintFormsEdit");
	ProfileDetails.Roles.Add("AddEditFoldersAndFiles");
	ProfileDetails.Roles.Add("_DemoBasicAccessSSL");
	ProfileDetails.Roles.Add("_DemoMySettings");
	
	// Use MasterData.
	ProfileDetails.Roles.Add("ReadWorkSchedules");
	ProfileDetails.Roles.Add("ReadCurrencyRates");
	ProfileDetails.Roles.Add("_DemoReadMasterData");
	
	// Standard features.
	ProfileDetails.Roles.Add("ViewRelatedDocuments");
	ProfileDetails.Roles.Add("ViewDocumentRecordsReport");
	ProfileDetails.Roles.Add("AddEditDigitalSignatureAndEncryptionApplications");
	ProfileDetails.Roles.Add("AddEditDigitalSignatureAndEncryptionKeyCertificates");
	ProfileDetails.Roles.Add("AddEditDigitalSignatures");
	ProfileDetails.Roles.Add("RemoveDigitalSignatures");
	ProfileDetails.Roles.Add("EncryptAndDecryptData");
	ProfileDetails.Roles.Add("UseDigitalSignatureInSaaS");
	ProfileDetails.Roles.Add("EditAdditionalInfo");
	ProfileDetails.Roles.Add("UseCurrentToDosProcessor");
	ProfileDetails.Roles.Add("ReadPeriodEndClosingDates");
	
	// Administrative features.
	ProfileDetails.Roles.Add("AddEditReportsOptions");
	ProfileDetails.Roles.Add("AddEditAdditionalReportsAndDataProcessors");
	ProfileDetails.Roles.Add("EditObjectAttributes");
	ProfileDetails.Roles.Add("UseUniversalReport");
	ProfileDetails.Roles.Add("AddEditReportsSnapshots");
	ProfileDetails.Roles.Add("_DemoExchangeMobileClient");
	
	// Basic profile features.
	ProfileDetails.Roles.Add("_DemoAddEditBankDocuments");
	ProfileDetails.Roles.Add("_DemoAddEditCashDocuments");
	ProfileDetails.Roles.Add("_DemoAddEditLeaves");
	ProfileDetails.Roles.Add("_DemoReadSalary");
	ProfileDetails.Roles.Add("_DemoReadRespondentsData");
	ProfileDetails.Roles.Add("_DemoReadJobsWithRoleAddressing");
	ProfileDetails.Roles.Add("_DemoReadCustomersDocuments");
	ProfileDetails.Roles.Add("_DemoAddEditRolePerformersByAddressingObjects");
	ProfileDetails.Roles.Add("_DemoAddEditProjects");
	ProfileDetails.Roles.Add("AddEditReportBulkEmails");
	ProfileDetails.Roles.Add("AddEditPerformersRoles");
	ProfileDetails.Roles.Add("EditPrintFormTemplates");
	ProfileDetails.Roles.Add("PerformanceSetupAndMonitoring");
	ProfileDetails.Roles.Add("ReadJobs");
	ProfileDetails.Roles.Add("ReadTasks");
	ProfileDetails.Roles.Add("ReadExternalUsers");
	ProfileDetails.Roles.Add("ReadQuestionnaireQuestionAnswers");
	ProfileDetails.Roles.Add("ReadObjectVersions");
	ProfileDetails.Roles.Add("SendSMSMessage");
	ProfileDetails.Roles.Add("AddEditEmailAccounts");
	ProfileDetails.Roles.Add("AddEditInteractions");
	ProfileDetails.Roles.Add("AddEditMessageTemplates");
	
	// Profile access restriction kinds.
	ProfileDetails.AccessKinds.Add("_DemoBusinessOperations", "Predefined");
	ProfileDetails.AccessKinds.Add("_DemoPartnerGroups", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Users", "AllDeniedByDefault");
	ProfileDetails.AccessValues.Add("_DemoBusinessOperations",
		"Enum._DemoBusinessOperations.SalaryPayment");
	
	// Use the "Data integrity" subsystem.
	ProfileDetails.Roles.Add("ReadAccountingCheckResults");
	
	
	SourceDocumentsOriginalsRecording.SupplementProfileWithRoleForDocumentsOriginalsStatesReading(ProfileDetails);
	SourceDocumentsOriginalsRecording.SupplementProfileWithRoleForDocumentsOriginalsStatesSetup(ProfileDetails);
	
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

Procedure FillAccountantProfile(Val ProfilesDetails)
	
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "_DemoAccountant";
	ProfileDetails.Id = "75fa0eca-98aa-11df-b54f-e0cb4ed5f655";
	ProfileDetails.Description  = NStr("ru = 'Бухгалтер';
										|en = 'Accountant';", Common.DefaultLanguageCode());
	ProfileDetails.LongDesc =
		NStr("ru = 'Демонстрирует использование
		           |- предустановленных видов доступа. Например, в отличие от профиля ""Руководитель""
		           |бухгалтерам разрешено редактировать документы ""Демо: Расходный кассовый ордер"" с типом
		           |хозяйственной операции - ""Выдача денежных средств подотчет"".
		           |- изменение как правило недоступных свойств объекта (на примере персональных данных физического лица).';
					|en = 'It demonstrates the use of
					|preset access kinds. For example, unlike the ""Officer"" profile
					|, an accountant is allowed to edit the ""Demo: Outgoing payment — Cash account"" documents with the
					|""Cash issue"" business transaction type.
					|As a rule, unavailable object properties are changed (on the example of individual personal data).';");
	
	// Use 1C:Enterprise.
	ProfileDetails.Roles.Add("StartWebClient");
	ProfileDetails.Roles.Add("StartThickClient");
	ProfileDetails.Roles.Add("StartThinClient");
	ProfileDetails.Roles.Add("StartMobileClient");
	ProfileDetails.Roles.Add("OutputToPrinterFileClipboard");
	ProfileDetails.Roles.Add("SaveUserData");
	
	// Use the application.
	AddRolesForAllCommandInterfaceSections(ProfileDetails);
	ProfileDetails.Roles.Add("BasicAccessSSL");
	ProfileDetails.Roles.Add("BasicAccessCTL");
	ProfileDetails.Roles.Add("BasicAccessOUS");
	ProfileDetails.Roles.Add("ViewApplicationChangeLog");
	ProfileDetails.Roles.Add("PrintFormsEdit");
	ProfileDetails.Roles.Add("AddEditFoldersAndFiles");
	ProfileDetails.Roles.Add("_DemoBasicAccessSSL");
	ProfileDetails.Roles.Add("_DemoMySettings");
	
	// Use MasterData.
	ProfileDetails.Roles.Add("ReadWorkSchedules");
	ProfileDetails.Roles.Add("ReadCurrencyRates");
	ProfileDetails.Roles.Add("_DemoReadMasterData");
	
	// Standard features.
	ProfileDetails.Roles.Add("AddEditPersonalReportsOptions");
	ProfileDetails.Roles.Add("AddEditPersonalMessageTemplates");
	ProfileDetails.Roles.Add("ReadAdditionalReportsAndDataProcessors");
	ProfileDetails.Roles.Add("_DemoUseSourceDocumentOriginalsJournalDataProcessor");
	ProfileDetails.Roles.Add("ViewRelatedDocuments");
	ProfileDetails.Roles.Add("UseCurrentToDosProcessor");
	ProfileDetails.Roles.Add("ReadPeriodEndClosingDates");
	
	// Basic profile features.
	ProfileDetails.Roles.Add("_DemoAddEditBankDocuments");
	ProfileDetails.Roles.Add("_DemoAddEditCashDocuments");
	
	// Profile access restriction kinds.
	ProfileDetails.AccessKinds.Add("_DemoStorageLocations",         "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("_DemoCompanies",                "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("_DemoCashAccounts",                 "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("_DemoPartnerGroups",       "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("AdditionalReportsAndDataProcessors", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Users",               "Predefined");
	ProfileDetails.AccessKinds.Add("_DemoBusinessOperations", "Predefined");
	ProfileDetails.AccessValues.Add("_DemoBusinessOperations",
		"Enum._DemoBusinessOperations.IssueCashToAdvanceHolder");
	ProfileDetails.AccessValues.Add("_DemoBusinessOperations",
		"Enum._DemoBusinessOperations.CashReturnByAdvanceHolder");
	
	SourceDocumentsOriginalsRecording.SupplementProfileWithRoleForDocumentsOriginalsStatesChange(ProfileDetails);
		
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

Procedure FillPayrollAndBenefitsOfficerProfile(Val ProfilesDetails)
	
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "_DemoSalaryCalculationManager";
	ProfileDetails.Id = "11851213-0f5f-11e0-96c1-e0cb4ed5f655";
	ProfileDetails.Description  = NStr("ru = 'Расчетчик зарплаты';
										|en = 'Payroll & benefits officer';",
		Common.DefaultLanguageCode());
	
	// Use 1C:Enterprise.
	ProfileDetails.Roles.Add("StartWebClient");
	ProfileDetails.Roles.Add("StartThickClient");
	ProfileDetails.Roles.Add("StartThinClient");
	ProfileDetails.Roles.Add("StartMobileClient");
	ProfileDetails.Roles.Add("OutputToPrinterFileClipboard");
	ProfileDetails.Roles.Add("SaveUserData");
	
	// Use the application.
	AddRolesForAllCommandInterfaceSections(ProfileDetails);
	ProfileDetails.Roles.Add("BasicAccessSSL");
	ProfileDetails.Roles.Add("BasicAccessCTL");
	ProfileDetails.Roles.Add("BasicAccessOUS");
	ProfileDetails.Roles.Add("ViewApplicationChangeLog");
	ProfileDetails.Roles.Add("PrintFormsEdit");
	ProfileDetails.Roles.Add("AddEditFoldersAndFiles");
	ProfileDetails.Roles.Add("_DemoBasicAccessSSL");
	ProfileDetails.Roles.Add("_DemoMySettings");
	
	// Use MasterData.
	ProfileDetails.Roles.Add("ReadWorkSchedules");
	ProfileDetails.Roles.Add("ReadCurrencyRates");
	ProfileDetails.Roles.Add("_DemoReadMasterData");
	
	// Standard features.
	ProfileDetails.Roles.Add("AddEditPersonalReportsOptions");
	ProfileDetails.Roles.Add("AddEditPersonalMessageTemplates");
	ProfileDetails.Roles.Add("ReadAdditionalReportsAndDataProcessors");
	ProfileDetails.Roles.Add("EditAdditionalInfo");
	ProfileDetails.Roles.Add("UseCurrentToDosProcessor");
	ProfileDetails.Roles.Add("ReadPeriodEndClosingDates");
	
	// Basic profile features.
	ProfileDetails.Roles.Add("_DemoAddEditSalary");
	
	// Profile access restriction kinds.
	ProfileDetails.AccessKinds.Add("_DemoStorageLocations", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("_DemoPartnerGroups", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("_DemoIndividuals", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("_DemoProductGroups", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("_DemoCompanies");
	ProfileDetails.AccessKinds.Add("Users", "Predefined");
	ProfileDetails.AccessKinds.Add("AdditionalReportsAndDataProcessors", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("AdditionalInfo", "AllDeniedByDefault");
	
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

Procedure FillAuditorProfile(Val ProfilesDetails)
	
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "_DemoAuditor";
	ProfileDetails.Id = "bfd56f51-313d-11e5-b1ac-e0cb4ed5f655";
	ProfileDetails.Description  = NStr("ru = 'Аудитор';
										|en = 'Auditor';", Common.DefaultLanguageCode());
	ProfileDetails.LongDesc      = NStr("ru = 'Позволяет просматривать любые данные.';
										|en = 'Allows to view any data.';");
	
	// Use 1C:Enterprise.
	ProfileDetails.Roles.Add("StartWebClient");
	ProfileDetails.Roles.Add("StartThickClient");
	ProfileDetails.Roles.Add("StartThinClient");
	ProfileDetails.Roles.Add("StartMobileClient");
	ProfileDetails.Roles.Add("OutputToPrinterFileClipboard");
	ProfileDetails.Roles.Add("SaveUserData");
	
	// Use the application.
	AddRolesForAllCommandInterfaceSections(ProfileDetails);
	ProfileDetails.Roles.Add("Subsystem_DemoSurvey");
	ProfileDetails.Roles.Add("BasicAccessSSL");
	ProfileDetails.Roles.Add("BasicAccessCTL");
	ProfileDetails.Roles.Add("BasicAccessOUS");
	ProfileDetails.Roles.Add("ViewApplicationChangeLog");
	ProfileDetails.Roles.Add("PrintFormsEdit");
	ProfileDetails.Roles.Add("AddEditFoldersAndFiles");
	ProfileDetails.Roles.Add("_DemoBasicAccessSSL");
	ProfileDetails.Roles.Add("_DemoMySettings");
	
	// Use MasterData.
	ProfileDetails.Roles.Add("ReadWorkSchedules");
	ProfileDetails.Roles.Add("ReadCurrencyRates");
	ProfileDetails.Roles.Add("_DemoReadMasterData");
	
	// Standard features.
	ProfileDetails.Roles.Add("ReadReportOptions");
	ProfileDetails.Roles.Add("ReadAdditionalReportsAndDataProcessors");
	ProfileDetails.Roles.Add("ViewRelatedDocuments");
	ProfileDetails.Roles.Add("DataDecryption");
	ProfileDetails.Roles.Add("UseDigitalSignatureInSaaS");
	ProfileDetails.Roles.Add("UseCurrentToDosProcessor");
	ProfileDetails.Roles.Add("ReadPeriodEndClosingDates");
	
	// Basic profile features.
	ProfileDetails.Roles.Add("_DemoReadBankDocuments");
	ProfileDetails.Roles.Add("_DemoReadRespondentsData");
	ProfileDetails.Roles.Add("_DemoReadCustomersDocuments");
	ProfileDetails.Roles.Add("_DemoReadJobsWithRoleAddressing");
	ProfileDetails.Roles.Add("_DemoReadSalary");
	ProfileDetails.Roles.Add("_DemoReadCashDocuments");
	ProfileDetails.Roles.Add("_DemoReadProjects");
	ProfileDetails.Roles.Add("_DemoReadInventoryTransfers");
	ProfileDetails.Roles.Add("_DemoReadWarehouseDocuments");
	ProfileDetails.Roles.Add("AddEditFoldersAndFiles");
	ProfileDetails.Roles.Add("ReadObjectVersions");
	ProfileDetails.Roles.Add("ReadExternalUsers");
	ProfileDetails.Roles.Add("ReadWorkSchedules");
	ProfileDetails.Roles.Add("ReadAdditionalInfo");
	ProfileDetails.Roles.Add("ReadJobs");
	ProfileDetails.Roles.Add("ReadTasks");
	ProfileDetails.Roles.Add("ReadObjectVersionInfo");
	ProfileDetails.Roles.Add("ReadReportBulkEmails");
	ProfileDetails.Roles.Add("ReadCurrencyRates");
	ProfileDetails.Roles.Add("ReadQuestionnaireQuestionAnswers");
	ProfileDetails.Roles.Add("ReadMessageTemplates");
	
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

Procedure FillPartnerProfile(Val ProfilesDetails)
	
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "_DemoPartner";
	ProfileDetails.Id = "67b8f689-ee30-11de-a1c1-005056c00008";
	ProfileDetails.Description  = NStr("ru = 'Партнер';
										|en = 'Partner';", Common.DefaultLanguageCode());
	
	// Override assignment.
	CommonClientServer.SupplementArray(ProfileDetails.Purpose,
		Metadata.DefinedTypes.ExternalUser.Type.Types());
	
	ProfileDetails.LongDesc =
		NStr("ru = 'Предназначен для партнеров (внешних пользователей), работающих с приложением.';
			|en = 'It is designed for partners (external users) that work with the application';");
	
	// Use 1C:Enterprise.
	ProfileDetails.Roles.Add("StartWebClient");
	ProfileDetails.Roles.Add("StartThinClient");
	ProfileDetails.Roles.Add("StartMobileClient");
	ProfileDetails.Roles.Add("OutputToPrinterFileClipboard");
	
	// Use the application.
	ProfileDetails.Roles.Add("BasicAccessExternalUserSSL");
	ProfileDetails.Roles.Add("_DemoInvoicesPaymentByExternalUsers");
	ProfileDetails.Roles.Add("UseCurrentToDosProcessor");
	ProfileDetails.Roles.Add("ReadAdditionalReportsAndDataProcessors");
	ProfileDetails.Roles.Add("_DemoReadAdditionalReportsAndDataProcessors");
	ProfileDetails.Roles.Add("AddEditPersonalReportsOptions");
	
	// Use MasterData.
	ProfileDetails.Roles.Add("ReadWorkSchedules");
	ProfileDetails.Roles.Add("ReadCurrencyRates");
	
	// Basic profile features.
	ProfileDetails.Roles.Add("_DemoReadDataForAnswersToQuestionnaireQuestions");
	ProfileDetails.Roles.Add("_DemoReadAuthorizationObjectsData");
	ProfileDetails.Roles.Add("ReadQuestionnaireQuestionAnswers");
	ProfileDetails.Roles.Add("AddEditQuestionnaireQuestionsAnswers");
	
	// File management.
	ProfileDetails.Roles.Add("AddEditFoldersAndFilesByExternalUsers");
	
	// Profile access restriction kinds.
	ProfileDetails.AccessKinds.Add("ExternalUsers", "Predefined");
	ProfileDetails.AccessKinds.Add("_DemoPartnerGroups", "Predefined");
	ProfileDetails.AccessKinds.Add("_DemoCompanies");
	ProfileDetails.AccessKinds.Add("AdditionalReportsAndDataProcessors");
	
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

// Additional profiles.

Procedure FillPersonResponsibleForMasterDataProfile(Val ProfilesDetails)
	
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "_DemoPersonResponsibleForReferenceInformation";
	ProfileDetails.Parent      = "AdditionalProfiles";
	ProfileDetails.Id = "09e56dbf-90a0-11de-862c-001d600d9fe2";
	ProfileDetails.Description  =
		NStr("ru = 'Ответственный за нормативно-справочную информацию (дополнительно)';
			|en = 'A person responsible for regulatory and legislation data (additional)';",
			Common.DefaultLanguageCode());
	ProfileDetails.LongDesc =
		NStr("ru = 'Ведение и обновление классификаторов, различной нормативно-справочной информации.';
			|en = 'Keeping and updating classifiers and various regulatory and legislation data.';");
	
	// Basic profile features.
	ProfileDetails.Roles.Add("AddEditAdditionalAttributesAndInfo");
	ProfileDetails.Roles.Add("AddEditCurrencyRates");
	ProfileDetails.Roles.Add("AddEditWorkSchedules");
	ProfileDetails.Roles.Add("AddEditBanks");
	ProfileDetails.Roles.Add("AddEditCalendarSchedules");
	ProfileDetails.Roles.Add("AddEditContactInfoKind");
	ProfileDetails.Roles.Add("AddEditFoldersAndFiles");
	ProfileDetails.Roles.Add("_DemoAddEditMasterData");
	ProfileDetails.Roles.Add("GetClassifiersUpdates");
	
	// Profile access restriction kinds.
	ProfileDetails.AccessKinds.Add("_DemoPartnerGroups");
	
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

Procedure FillPersonResponsibleForProductsProfile(Val ProfilesDetails)
	
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "_DemoPersonResponsibleForProductManagement";
	ProfileDetails.Parent      = "AdditionalProfiles";
	ProfileDetails.Id = "d348b8f5-1437-11e2-bb53-005056c00008";
	ProfileDetails.Description  =
		NStr("ru = 'Ответственный за ведение номенклатуры (дополнительно)';
			|en = 'Person responsible for products (additional)';",
			Common.DefaultLanguageCode());
	ProfileDetails.LongDesc =
		NStr("ru = 'Назначается тем пользователям, которые будут добавлять или изменять номенклатуру.';
			|en = 'It is assigned to those users who will be add or change a product.';");
	
	// Basic profile features.
	ProfileDetails.Roles.Add("_DemoAddEditProducts");
	// MasterData management available in some countries.
	ProfileDetails.Roles.Add("AddEditContactInfoKind");
	
	// Profile access restriction kinds.
	ProfileDetails.AccessKinds.Add("_DemoProductGroups", "AllAllowedByDefault");
	
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

Procedure FillPersonResponsibleForInteractionsProfile(Val ProfilesDetails)
	
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "_DemoPersonResponsibleForInteractions";
	ProfileDetails.Parent      = "AdditionalProfiles";
	ProfileDetails.Id = "62e89fcd-9a4c-11df-8c0e-0011d8570cdf";
	ProfileDetails.Description  =
		NStr("ru = 'Ответственный за ведение взаимодействий (дополнительно)';
			|en = 'Employee responsible for interactions (additional)';",
			Common.DefaultLanguageCode());
	ProfileDetails.LongDesc =
		NStr("ru = 'Ведение взаимодействий с клиентами, поставщиками, партнерами и т.п. по электронной почте и телефону,
		           |а также планирование встреч (подсистема ""Взаимодействия"").';
					|en = 'Keeping Interactions with customers, suppliers, partners and so on via email and phone,
					| as well as scheduling meetings (the ""Interactions"" subsystem).';");
	
	// Basic profile features.
	ProfileDetails.Roles.Add("ReadEmailAccounts");
	ProfileDetails.Roles.Add("AddEditInteractions");
	
	// Profile access restriction kinds.
	ProfileDetails.AccessKinds.Add("_DemoPartnerGroups", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("Users", "AllAllowedByDefault");
	ProfileDetails.AccessKinds.Add("EmailAccounts");
	
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

Procedure FillPersonResponsibleForUsersListProfile(Val ProfilesDetails)
	
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "_DemoPersonResponsibleForUserList";
	ProfileDetails.Parent      = "AdditionalProfiles";
	ProfileDetails.Id = "71ab566d-313b-11e5-b1ac-e0cb4ed5f655";
	ProfileDetails.Description  =
		NStr("ru = 'Ответственный за список пользователей (дополнительно)';
			|en = 'Person responsible for the user list (additional)';",
			Common.DefaultLanguageCode());
	ProfileDetails.LongDesc =
		NStr("ru = 'Дополнительно назначается тем пользователям, которым должна быть
		           |доступна возможность добавления и изменения пользователей,
		           |настройка свойств пользователей информационной базы (без разрешения входа)
		           |(подсистема ""Пользователи"").';
					|en = 'It is additionally assigned to those users who must be able
					|to add and edit users and
					|set up infobase user properties (without access permission)
					|(the ""Users"" subsystem).';");
	
	// Basic profile features.
	ProfileDetails.Roles.Add("AddEditUsers");
	ProfileDetails.Roles.Add("Subsystem_DemoAdministration");
	
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

Procedure FillPersonResponsibleForExternalUsersListProfile(Val ProfilesDetails)
	
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "_DemoPersonResponsibleForExternalUserList";
	ProfileDetails.Parent      = "AdditionalProfiles";
	ProfileDetails.Id = "14401b24-3591-11df-863c-001d600d9ad2";
	ProfileDetails.Description  =
		NStr("ru = 'Ответственный за список внешних пользователей (дополнительно)';
			|en = 'Person responsible for the external user list (additional)';",
			Common.DefaultLanguageCode());
	ProfileDetails.LongDesc =
		NStr("ru = 'Дополнительно назначается тем пользователям, которым должна быть
		           |доступна возможность добавления и изменения внешних пользователей,
		           |настройка свойств пользователей информационной базы (без разрешения входа)
		           |(подсистема ""Пользователи"").';
					|en = 'It is additionally assigned to those users who must be able
					|to add and edit users and
					|set up properties of external infobase users (without access permission)
					|(the ""Users"" subsystem).';");
	
	// Basic profile features.
	ProfileDetails.Roles.Add("AddEditExternalUsers");
	ProfileDetails.Roles.Add("Subsystem_DemoAdministration");
	
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

Procedure FillPersonResponsibleForAccessGroupsMembersListProfile(Val ProfilesDetails)
	
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "_DemoPersonResponsibleForAccessGroupMemberLists";
	ProfileDetails.Parent      = "AdditionalProfiles";
	ProfileDetails.Id = "588438ff-e954-11de-8634-001d600d9ad2";
	ProfileDetails.Description  =
		NStr("ru = 'Ответственный за составы участников групп доступа (дополнительно)';
			|en = 'Person responsible for access group member lists (additional)';",
			Common.DefaultLanguageCode());
	ProfileDetails.LongDesc =
		NStr("ru = 'Назначается тем пользователям, у которых должна быть
		           |возможность изменять состав участников своих групп доступа
		           |(подсистема ""Управление доступом"").';
					|en = 'It is assigned to those users who must be
					|able to change composition of their access group members
					|(the ""Access management"" subsystem).';");
	
	// Basic profile features.
	ProfileDetails.Roles.Add("EditAccessGroupMembers");
	ProfileDetails.Roles.Add("Subsystem_DemoAdministration");
	
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

Procedure FillSetUpFilesSynchronizationWithCloudServiceProfile(Val ProfilesDetails)
	
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "_DemoSettingsForFileSynchronizationWithCloudService";
	ProfileDetails.Parent      = "AdditionalProfiles";
	ProfileDetails.Id = "3b9c663c-496d-11e5-9e02-50465da19b8f";
	ProfileDetails.Description  =
		NStr("ru = 'Настройка синхронизации файлов с облачным сервисом (дополнительно)';
			|en = 'Setting synchronization of files with cloud service.';",
			Common.DefaultLanguageCode());
	ProfileDetails.LongDesc =
		NStr("ru = 'Дополнительно назначается тем пользователям, которым должна быть
		           |доступна настройка синхронизации файлов с облачными сервисами.';
					|en = 'It is additionally assigned to those users who must be
					|able to set up synchronization of files with cloud service.';");
	
	// Basic profile features.
	ProfileDetails.Roles.Add("FilesSynchronizationSetup");
	
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

Procedure FillPersonResponsibleForPeriodEndClosingDatesProfile(Val ProfilesDetails)
	
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "_DemoPersonResponsibleForPeriodEndClosingDates";
	ProfileDetails.Parent      = "AdditionalProfiles";
	ProfileDetails.Id = "170b789c-3065-11e5-b1ac-e0cb4ed5f655";
	ProfileDetails.Description  =
		NStr("ru = 'Ответственный за даты запрета изменения данных (дополнительно)';
			|en = 'A person responsible for period-end closing dates (additional)';",
			Common.DefaultLanguageCode());
	ProfileDetails.LongDesc =
		NStr("ru = 'Дополнительно назначается тем пользователям, которым должна быть
		           |доступна возможность работы с датами запрета изменения данных
		           |(подсистема ""Даты запрета изменения"").';
					|en = 'It is additionally assigned to those users who must be able
					|to work with period-end closing dates
					|(The ""Period-end closing dates"" subsystem).';");
	
	// Basic profile features.
	ProfileDetails.Roles.Add("AddEditPeriodClosingDates");
	
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

Procedure PopulateProfileResponsibleForDataImportRestrictionDates(Val ProfilesDetails)
	
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "_DemoPersonResponsibleForDataImportRestrictionDates";
	ProfileDetails.Parent      = "AdditionalProfiles";
	ProfileDetails.Id = "c42ea2e6-b860-45ac-99b3-f0a8a0cf1ba5";
	ProfileDetails.Description  =
		NStr("ru = 'Ответственный за даты запрета загрузки данных (дополнительно)';
			|en = 'A person responsible for data import restriction dates (additional)';",
			Common.DefaultLanguageCode());
	ProfileDetails.LongDesc =
		NStr("ru = 'Дополнительно назначается тем пользователям, которым должна быть
		           |доступна возможность работы с датами запрета загрузки данных
		           |(подсистема ""Даты запрета изменения"" для подсистемы ""Обмен данными"").';
					|en = 'It is additionally assigned to users who must be able
					|to work with data import restriction dates
					|(the ""Period-end closing dates"" subsystem for the ""Data exchange"" subsystem).';");
	
	// Basic profile features.
	ProfileDetails.Roles.Add("AddEditDataImportRestrictionDates");
	
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

Procedure FillEmailUsageProfile(Val ProfilesDetails)
	
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "_DemoEmailUsage";
	ProfileDetails.Parent      = "AdditionalProfiles";
	ProfileDetails.Id = "588438ff-e854-11de-8634-001d600d9ad1";
	ProfileDetails.Description  = NStr("ru = 'Использование электронной почты (дополнительно)';
										|en = 'Advanced: Use email';",
		Common.DefaultLanguageCode());
	ProfileDetails.LongDesc =
		NStr("ru = 'Дополнительно назначается тем пользователям, которым должны быть
		           |доступны различные функции получения и отправки электронной почты,
		           |имеющиеся в системе.';
					|en = 'It is additionally assigned to those users who must have
					|access to different function of receiving and sending emails
					|that the application has.';");
	
	// Basic profile features.
	ProfileDetails.Roles.Add("AddEditEmailAccounts");
	ProfileDetails.Roles.Add("_DemoEmailOperations");
	
	// Profile access restriction kinds.
	ProfileDetails.AccessKinds.Add("EmailAccounts");
	ProfileDetails.AccessKinds.Add("Users");
	
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

Procedure FillUnpostedDocumentsPrintProfile(Val ProfilesDetails)
	
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "_DemoPrintUnpostedDocuments";
	ProfileDetails.Parent      = "AdditionalProfiles";
	ProfileDetails.Id = "c944ca49-dfee-11de-8632-001d600d9ad2";
	ProfileDetails.Description  = NStr("ru = 'Печать непроведенных документов (дополнительно)';
										|en = 'Print unposted documents (additional)';",
		Common.DefaultLanguageCode());
	ProfileDetails.LongDesc = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Дополнительно назначается тем пользователям, которым должна быть
		           |доступна печать непроведенных документов.
		           |Демонстрирует использование функции %1.';
					|en = 'It is additionally assigned to those users who must have
					|access to printing unposted documents.
					|It demonstrates the use of %1 function.';"), "HasRole");
	
	// Basic profile features.
	ProfileDetails.Roles.Add("_DemoPrintUnpostedDocuments");
	
	// Profile access restriction kinds.
	ProfileDetails.AccessKinds.Add("_DemoStorageLocations");
	ProfileDetails.AccessKinds.Add("_DemoCompanies");
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

Procedure FillFilesFoldersOperationsProfile(Val ProfilesDetails)
	
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "_DemoFileFolderOperations";
	ProfileDetails.Parent      = "AdditionalProfiles";
	ProfileDetails.Id = "a8f63f6c-ced9-11de-862f-001d600d9ad2";
	ProfileDetails.Description  = NStr("ru = 'Работа с папками файлов (дополнительно)';
										|en = 'Operations with file folders (additional)';",
		Common.DefaultLanguageCode());
	ProfileDetails.LongDesc =
		NStr("ru = 'Дополнительно назначается тем пользователям, которым разрешено
		           |работать с папками файлов (подсистема ""Работа с файлами"").';
					|en = 'It is additionally assigned to those users who are allowed
					|to work with file folders (the ""File management"" subsystem).';");
	
	// Basic profile features.
	ProfileDetails.Roles.Add("AddEditFoldersAndFiles");
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

Procedure FillEditConsentsToPersonalDataProcessingProfile(Val ProfilesDetails)
 
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "_DemoEditConsentForPersonalDataProcessing";
	ProfileDetails.Parent      = "AdditionalProfiles";
	ProfileDetails.Id = "3d09f30d-0d95-403c-b2ab-c39780da6a95";
	ProfileDetails.Description  =
		NStr("ru = 'Редактирование согласий на обработку персональных данных (дополнительно)';
			|en = 'Edit consents to personal data processing (additional)';",
			Common.DefaultLanguageCode());
	ProfileDetails.LongDesc =
		NStr("ru = 'Добавление и изменение согласий на обработку персональных данных.';
			|en = 'Add and update consents to personal data processing.';");
	
	// Basic profile features.
	ProfileDetails.Roles.Add("_DemoAddEditPersonalDataProcessingConsents");
	
	// Profile access restriction kinds.
	ProfileDetails.AccessKinds.Add("_DemoCompanies");
	
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

Procedure FillViewConsentsToPersonalDataProcessingProfile(Val ProfilesDetails)
	
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "_DemoViewConsentForPersonalDataProcessing";
	ProfileDetails.Parent      = "AdditionalProfiles";
	ProfileDetails.Id = "53c4eecf-9401-450b-9c15-15872be591e5";
	ProfileDetails.Description  =
		NStr("ru = 'Просмотр согласий на обработку персональных данных (дополнительно)';
			|en = 'View consents to personal data processing (additional)';",
			Common.DefaultLanguageCode());
	ProfileDetails.LongDesc = NStr("ru = 'Просмотр согласий на обработку персональных данных.';
									|en = 'View consents to personal data processing.';");
	
	// Basic profile features.
	ProfileDetails.Roles.Add("_DemoReadPersonalDataProcessingConsents");
	
	// Profile access restriction kinds.
	ProfileDetails.AccessKinds.Add("_DemoCompanies");
	
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

// For the FillProfile* procedures.
Procedure AddRolesForAllCommandInterfaceSections(Val ProfileDetails)
	
	ProfileDetails.Roles.Add("Subsystem_DemoBusinessProcessesAndTasks");
	ProfileDetails.Roles.Add("Subsystem_DemoIntegratedSubsystems");
	ProfileDetails.Roles.Add("Subsystem_DemoIntegratedSubsystemsFollowUp");
	ProfileDetails.Roles.Add("Subsystem_DemoMasterData");
	ProfileDetails.Roles.Add("Subsystem_DemoOrganizer");
	ProfileDetails.Roles.Add("Subsystem_DemoServiceSubsystems");
	ProfileDetails.Roles.Add("Subsystem_DemoDataSynchronization");
	ProfileDetails.Roles.Add("Subsystem_DemoAccessManagement");
	
EndProcedure

// Populate access set values.

Procedure OnFillAccessValuesSetsForMeeting(Object, Table)

	// The access logic is as follows: the object is available if either "Author" or "EmployeeResponsible" is set.
	// The "OR" condition is implemented using the set numbers.

	// Restrict by EmailAccounts.
	SetNumber = 1;
	
	TabRow = Table.Add();
	TabRow.SetNumber     = SetNumber;
	TabRow.AccessValue = Object.Author;

	// Restrict by PersonResponsible.
	SetNumber = SetNumber + 1;

	TabRow = Table.Add();
	TabRow.SetNumber     = SetNumber;
	TabRow.AccessValue = Object.EmployeeResponsible;

	ContactPersons = New Array;
	For Each TableRow In Object.Attendees Do

		If Not ValueIsFilled(TableRow.Contact) Then
			Continue;
		EndIf;

		If TypeOf(TableRow.Contact) = Type("CatalogRef._DemoPartners") Then

			SetNumber = SetNumber + 1;

			TabRow = Table.Add();
			TabRow.SetNumber     = SetNumber;
			TabRow.AccessValue = TableRow.Contact;

		ElsIf TypeOf(TableRow.Contact) = Type("CatalogRef._DemoPartnersContactPersons") Then

			ContactPersons.Add(TableRow.Contact);

		EndIf;

	EndDo;

	If ContactPersons.Count() > 0 Then

		Selection = ChoosePartners(ContactPersons);
		While Selection.Next() Do

			SetNumber = SetNumber + 1;

			TabRow = Table.Add();
			TabRow.SetNumber     = SetNumber;
			TabRow.AccessValue = Selection.Partner;

		EndDo;

	EndIf;

EndProcedure

Procedure OnFillAccessValuesSetsForScheduledInteraction(Object, Table)

	// The access logic is as follows: the object is available if either "Author" or "EmployeeResponsible" is set.
	// The "OR" condition is implemented using the set numbers.

	// Restrict by EmailAccounts.
	SetNumber = 1;

	TabRow = Table.Add();
	TabRow.SetNumber     = SetNumber;
	TabRow.AccessValue = Object.Author;

	// Restrict by PersonResponsible.
	SetNumber = SetNumber + 1;

	TabRow = Table.Add();
	TabRow.SetNumber     = SetNumber;
	TabRow.AccessValue = Object.EmployeeResponsible;

	ContactPersons = New Array;
	For Each TableRow In Object.Attendees Do

		If Not ValueIsFilled(TableRow.Contact) Then
			Continue;
		EndIf;

		If TypeOf(TableRow.Contact) = Type("CatalogRef._DemoPartners") Then

			SetNumber = SetNumber + 1;

			TabRow = Table.Add();
			TabRow.SetNumber     = SetNumber;
			TabRow.AccessValue = TableRow.Contact;

		ElsIf TypeOf(TableRow.Contact) = Type("CatalogRef._DemoPartnersContactPersons") Then

			ContactPersons.Add(TableRow.Contact);

		EndIf;

	EndDo;

	If ContactPersons.Count() > 0 Then

		Selection = ChoosePartners(ContactPersons);
		While Selection.Next() Do

			SetNumber = SetNumber + 1;

			TabRow = Table.Add();
			TabRow.SetNumber     = SetNumber;
			TabRow.AccessValue = Selection.Partner;

		EndDo;

	EndIf;	

EndProcedure

Procedure OnFillAccessValuesSetsForSMSMessage(Object, Table)

	// The access logic is as follows: the object is available if either "Author" or "EmployeeResponsible" is set.
	// The "OR" condition is implemented using the set numbers.

	// Restrict by EmailAccounts.
	SetNumber = 1;

	TabRow = Table.Add();
	TabRow.SetNumber     = SetNumber;
	TabRow.AccessValue = Object.Author;

	// Restrict by PersonResponsible.
	SetNumber = SetNumber + 1;

	TabRow = Table.Add();
	TabRow.SetNumber     = SetNumber;
	TabRow.AccessValue = Object.EmployeeResponsible;

	ContactPersons = New Array;
	For Each TableRow In Object.SMSMessageRecipients Do

		If Not ValueIsFilled(TableRow.Contact) Then
			Continue;
		EndIf;

		If TypeOf(TableRow.Contact) = Type("CatalogRef._DemoPartners") Then

			SetNumber = SetNumber + 1;

			TabRow = Table.Add();
			TabRow.SetNumber     = SetNumber;
			TabRow.AccessValue = TableRow.Contact;

		ElsIf TypeOf(TableRow.Contact) = Type("CatalogRef._DemoPartnersContactPersons") Then

			ContactPersons.Add(TableRow.Contact);

		EndIf;

	EndDo;

	If ContactPersons.Count() > 0 Then

		Selection = ChoosePartners(ContactPersons);
		While Selection.Next() Do

			SetNumber = SetNumber + 1;

			TabRow = Table.Add();
			TabRow.SetNumber     = SetNumber;
			TabRow.AccessValue = Selection.Partner;

		EndDo;

	EndIf;
	
EndProcedure

Procedure OnFillAccessValuesSetsForPhoneCall(Object, Table)

	// The access logic is as follows: the object is available if either "Author" or "EmployeeResponsible" is set.
	// The "OR" condition is implemented using the set numbers.
	
	// Restrict by Author.
	SetNumber = 1;

	TableRow = Table.Add();
	TableRow.SetNumber     = SetNumber;
	TableRow.AccessValue = Object.Author;

	// Restrict by PersonResponsible.
	SetNumber = SetNumber + 1;

	TableRow = Table.Add();
	TableRow.SetNumber     = SetNumber;
	TableRow.AccessValue = Object.EmployeeResponsible;

	If ValueIsFilled(Object.SubscriberContact) Then

		If TypeOf(Object.SubscriberContact) = Type("CatalogRef._DemoPartners") Then

			SetNumber = SetNumber + 1;

			TableRow = Table.Add();
			TableRow.SetNumber     = SetNumber;
			TableRow.AccessValue = Object.SubscriberContact;

		ElsIf TypeOf(Object.SubscriberContact) = Type("CatalogRef._DemoPartnersContactPersons") Then

			ContactPersons = CommonClientServer.ValueInArray(Object.SubscriberContact);
			Selection = ChoosePartners(ContactPersons);
			While Selection.Next() Do

				SetNumber = SetNumber + 1;

				TableRow = Table.Add();
				TableRow.SetNumber     = SetNumber;
				TableRow.AccessValue = Selection.Partner;

			EndDo;
		EndIf;
	EndIf;

EndProcedure

Procedure OnFillAccessValuesSetsForIncomingEmail(Object, Table)

	// The access logic is as follows: the object is available if either "EmployeeResponsible" or "Account" is set.
	// The "OR" condition is implemented using the set numbers.

	// Restrict by EmailAccounts.
	SetNumber = 1;

	TabRow = Table.Add();
	TabRow.SetNumber     = SetNumber;
	TabRow.AccessValue = Object.Account;

	// Restrict by PersonResponsible.
	SetNumber = SetNumber + 1;

	TabRow = Table.Add();
	TabRow.SetNumber     = SetNumber;
	TabRow.AccessValue = Object.EmployeeResponsible;

	ContactPersons = New Array;

	TabularSectionsArray = New Array;
	TabularSectionsArray.Add("EmailRecipients");
	TabularSectionsArray.Add("CCRecipients");
	TabularSectionsArray.Add("ReplyRecipients");
	For Each TabularSection In TabularSectionsArray Do

		For Each TableRow In Object[TabularSection] Do

			If Not ValueIsFilled(TableRow.Contact) Then
				Continue;
			EndIf;

			If TypeOf(TableRow.Contact) = Type("CatalogRef._DemoPartners") Then

				SetNumber = SetNumber + 1;

				TabRow = Table.Add();
				TabRow.SetNumber     = SetNumber;
				TabRow.AccessValue = TableRow.Contact;

			ElsIf TypeOf(TableRow.Contact) = Type("CatalogRef._DemoPartnersContactPersons") Then

				ContactPersons.Add(TableRow.Contact);

			EndIf;

		EndDo;
	EndDo;

	If ContactPersons.Count() > 0 Then

		Selection = ChoosePartners(ContactPersons);
		While Selection.Next() Do

			SetNumber = SetNumber + 1;

			TabRow = Table.Add();
			TabRow.SetNumber     = SetNumber;
			TabRow.AccessValue = Selection.Partner;

		EndDo;

	EndIf;

EndProcedure

Procedure OnFillAccessValuesSetsForOutgoingEmail(Object, Table)

	// The access logic is as follows: the object is available if either "EmployeeResponsible", "Author", or "Account" is set.
	// The "OR" condition is implemented using the set numbers.
	// 

	SetNumber = 1;

	TableRow = Table.Add();
	TableRow.SetNumber     = SetNumber;
	TableRow.AccessValue = Object.Account;

	SetNumber = SetNumber + 1;

	TableRow = Table.Add();
	TableRow.SetNumber     = SetNumber;
	TableRow.AccessValue = Object.Author;

	SetNumber = SetNumber + 1;

	TableRow = Table.Add();
	TableRow.SetNumber     = SetNumber;
	TableRow.AccessValue = Object.EmployeeResponsible;

	ContactPersons = New Array;

	TabularSectionsArray = New Array;
	TabularSectionsArray.Add("EmailRecipients");
	TabularSectionsArray.Add("CCRecipients");
	TabularSectionsArray.Add("ReplyRecipients");
	TabularSectionsArray.Add("BccRecipients");
	For Each TabularSection In TabularSectionsArray Do

		For Each TableRow In Object[TabularSection] Do

			If Not ValueIsFilled(TableRow.Contact) Then
				Continue;
			EndIf;

			If TypeOf(TableRow.Contact) = Type("CatalogRef._DemoPartners") Then

				SetNumber = SetNumber + 1;

				NewRow = Table.Add();
				NewRow.SetNumber     = SetNumber;
				NewRow.AccessValue = TableRow.Contact;

			ElsIf TypeOf(TableRow.Contact) = Type("CatalogRef._DemoPartnersContactPersons") Then

				ContactPersons.Add(TableRow.Contact);

			EndIf;

		EndDo;
	EndDo;

	If ContactPersons.Count() > 0 Then

		Selection = ChoosePartners(ContactPersons);
		While Selection.Next() Do

			SetNumber = SetNumber + 1;

			NewRow = Table.Add();
			NewRow.SetNumber     = SetNumber;
			NewRow.AccessValue = Selection.Partner;

		EndDo;

	EndIf;

EndProcedure

Function ChoosePartners(ContactPersons)
	
	Query = New Query(
	"SELECT DISTINCT
	|	ContactPersonsForPartners.Owner AS Partner
	|FROM
	|	Catalog._DemoPartnersContactPersons AS ContactPersonsForPartners
	|WHERE
	|	ContactPersonsForPartners.Ref IN(&ArrayOfContactPersons)
	|");
	Query.SetParameter("ArrayOfContactPersons", ContactPersons);
	Return Query.Execute().Select();

EndFunction

// Populate access restriction.

Procedure OnFillAccessRestrictionForMeeting(Restriction)
	
	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(EmployeeResponsible, Disabled AS FALSE)
	|	OR ValueAllowed(Author, Disabled AS FALSE)
	|	OR ValueAllowed(Attendees.Contact ONLY Catalog._DemoPartners, Disabled AS FALSE)
	|	OR ValueAllowed(CAST(Attendees.Contact AS Catalog._DemoPartnersContactPersons).Owner, Disabled AS FALSE)";
	
EndProcedure

Procedure OnFillAccessRestrictionForScheduledInteraction(Restriction)
	
	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(EmployeeResponsible, Disabled AS FALSE)
	|	OR ValueAllowed(Author, Disabled AS FALSE)
	|	OR ValueAllowed(Attendees.Contact ONLY Catalog._DemoPartners, Disabled AS FALSE)
	|	OR ValueAllowed(CAST(Attendees.Contact AS Catalog._DemoPartnersContactPersons).Owner, Disabled AS FALSE)";
	
EndProcedure

Procedure OnFillAccessRestrictionForSMSMessage(Restriction)
	
	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(EmployeeResponsible, Disabled AS FALSE)
	|	OR ValueAllowed(Author, Disabled AS FALSE)
	|	OR ValueAllowed(SMSMessageRecipients.Contact ONLY Catalog._DemoPartners, Disabled AS FALSE)
	|	OR ValueAllowed(CAST(SMSMessageRecipients.Contact AS Catalog._DemoPartnersContactPersons).Owner, Disabled AS FALSE)";
	
EndProcedure

Procedure OnFillAccessRestrictionForPhoneCall(Restriction)
	
	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(EmployeeResponsible, Disabled AS FALSE)
	|	OR ValueAllowed(Author, Disabled AS FALSE)
	|	OR ValueAllowed(SubscriberContact ONLY Catalog._DemoPartners, Disabled AS FALSE)
	|	OR ValueAllowed(CAST(SubscriberContact AS Catalog._DemoPartnersContactPersons).Owner, Disabled AS FALSE)";
	
EndProcedure

Procedure OnFillAccessRestrictionForIncomingEmail(Restriction)
	
	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(EmployeeResponsible, Disabled AS FALSE)
	|	OR CASE WHEN Account.AccountOwner = VALUE(Catalog.Users.EmptyRef) THEN
	|			ValueAllowed(Account, Disabled AS FALSE)
	|		ELSE
	|			IsAuthorizedUser(Account.AccountOwner)
	|		END
	|	OR ValueAllowed(EmailRecipients.Contact ONLY Catalog._DemoPartners, Disabled AS FALSE)
	|	OR ValueAllowed(CAST(EmailRecipients.Contact AS Catalog._DemoPartnersContactPersons).Owner, Disabled AS FALSE)
	|	OR ValueAllowed(CCRecipients.Contact ONLY Catalog._DemoPartners, Disabled AS FALSE)
	|	OR ValueAllowed(CAST(CCRecipients.Contact AS Catalog._DemoPartnersContactPersons).Owner, Disabled AS FALSE)
	|	OR ValueAllowed(ReplyRecipients.Contact ONLY Catalog._DemoPartners, Disabled AS FALSE)
	|	OR ValueAllowed(CAST(ReplyRecipients.Contact AS Catalog._DemoPartnersContactPersons).Owner, Disabled AS FALSE)";
	
EndProcedure

Procedure OnFillAccessRestrictionForOutgoingEmail(Restriction)
	
	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(EmployeeResponsible, Disabled AS FALSE)
	|	OR ValueAllowed(Author, Disabled AS FALSE)
	|	OR CASE WHEN Account.AccountOwner = VALUE(Catalog.Users.EmptyRef) THEN
	|			ValueAllowed(Account, Disabled AS FALSE)
	|		ELSE
	|			IsAuthorizedUser(Account.AccountOwner)
	|		END
	|	OR ValueAllowed(EmailRecipients.Contact ONLY Catalog._DemoPartners, Disabled AS FALSE)
	|	OR ValueAllowed(CAST(EmailRecipients.Contact AS Catalog._DemoPartnersContactPersons).Owner, Disabled AS FALSE)
	|	OR ValueAllowed(CCRecipients.Contact ONLY Catalog._DemoPartners, Disabled AS FALSE)
	|	OR ValueAllowed(CAST(CCRecipients.Contact AS Catalog._DemoPartnersContactPersons).Owner, Disabled AS FALSE)
	|	OR ValueAllowed(ReplyRecipients.Contact ONLY Catalog._DemoPartners, Disabled AS FALSE)
	|	OR ValueAllowed(CAST(ReplyRecipients.Contact AS Catalog._DemoPartnersContactPersons).Owner, Disabled AS FALSE)
	|	OR ValueAllowed(BccRecipients.Contact ONLY Catalog._DemoPartners, Disabled AS FALSE)
	|	OR ValueAllowed(CAST(BccRecipients.Contact AS Catalog._DemoPartnersContactPersons).Owner, Disabled AS FALSE)";
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Implementation of the event OnPrepareDataSet.

Function FieldsPresentationNames(RegisterFields)
	
	Result = New Structure;
	
	IsExcludableType = Type("ValueStorage");
	For Each MetadataUnit In RegisterFields Do
		If Not MetadataUnit.Type.ContainsType(IsExcludableType) Then 
			Result.Insert(MetadataUnit.Name, MetadataUnit.Presentation());
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

Procedure AddFields(SelectionFieldsText, FieldsPresentationNames)
	
	For Each Field In FieldsPresentationNames Do
		SelectionFieldsText = SelectionFieldsText + ?(ValueIsFilled(SelectionFieldsText), ", ", "") + Field.Key;
	EndDo;
	
EndProcedure

Function FieldsNumbers(MaxNumber)
	
	Result = New Structure;
	
	For IndexOf = 1 To MaxNumber Do
		IndexAsString = Format(IndexOf, "NG=0");
		Result.Insert("CurrentDocumentDCSOutputItemGroup" + IndexAsString, IndexAsString);
	EndDo;
	
	Return Result;
	
EndFunction

Procedure AddFieldsNumbers(FieldsNumbersText, FieldsNumbers)
	
	For Each FieldNumber In FieldsNumbers Do
		FieldsNumbersText = FieldsNumbersText + ?(ValueIsFilled(FieldsNumbersText), ", ", "") + FieldNumber.Value + " AS "
			+ FieldNumber.Key;
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Implementation of the event OnDuplicatesSearchParametersDefine.

// Abbreviations of legal structures used in short names of legal entities. 
// Based on the "Instruction on the accounting for legal entities and their subdivisions", in the unified state register of enterprises and organizations.
// Chapter i (as approved by the Federal State Statistic Service of the Russian Federation 22.12.99 No. ac-1-24/6483, ed. 12/07/2001). 
//  
// 
//
Function LegalFormsAbbreviations()
	ShortForms = New Array();
	ShortForms.Add("SUE");
	ShortForms.Add("FKP");
	ShortForms.Add("MUUP");
	ShortForms.Add("DUP");
	ShortForms.Add("DP");
	ShortForms.Add("PK");
	ShortForms.Add("ART");
	ShortForms.Add("SKHK");
	ShortForms.Add("PT");
	ShortForms.Add("TV");
	ShortForms.Add("LLC");
	ShortForms.Add("SLC");
	ShortForms.Add("JSC");
	ShortForms.Add("CJSC2");
	ShortForms.Add("PL");
	ShortForms.Add("PRED");
	ShortForms.Add("OO");
	ShortForms.Add("RO");
	ShortForms.Add("OOB");
	ShortForms.Add("ROB");
	ShortForms.Add("NP");
	ShortForms.Add("Land1");
	ShortForms.Add("SA");
	ShortForms.Add("MUC");
	ShortForms.Add("OUC");
	ShortForms.Add("INPO");
	ShortForms.Add("AC");
	ShortForms.Add("TCZ");
	ShortForms.Add("PTC");
	ShortForms.Add("DA");
	ShortForms.Add("OF");
	ShortForms.Add("OOS");
	ShortForms.Add("TEI");
	ShortForms.Add("OPROF");
	ShortForms.Add("TOPROF");
	ShortForms.Add("PPO");
	ShortForms.Add("AD");
	ShortForms.Add("CJSC");
	ShortForms.Add("OJSC");
	ShortForms.Add("TOO");
	ShortForms.Add("MP");
	ShortForms.Add("INDIVIDUALENTREPRENEUR1");
	ShortForms.Add("SEM");
	ShortForms.Add("KFH");
	ShortForms.Add("KH");
	ShortForms.Add("SP");
	ShortForms.Add("GP");
	ShortForms.Add("MUP");
	ShortForms.Add("POO");
	ShortForms.Add("PPKOOP");
	ShortForms.Add("UOO");
	ShortForms.Add("UCPTK");
	ShortForms.Add("SMT");
	ShortForms.Add("ST");
	ShortForms.Add("KLH");
	ShortForms.Add("SVH");
	ShortForms.Add("ZSK");
	ShortForms.Add("GCC");
	ShortForms.Add("NPO");
	ShortForms.Add("ON");
	ShortForms.Add("SKB");
	ShortForms.Add("KB");
	ShortForms.Add("UPTK");
	ShortForms.Add("SMU");
	ShortForms.Add("HOZU");
	ShortForms.Add("NTC");
	ShortForms.Add("FIK");
	ShortForms.Add("NBSP");
	ShortForms.Add("CIF");
	ShortForms.Add("CHOP");
	ShortForms.Add("REU");
	ShortForms.Add("MUTUALFUNDS");
	ShortForms.Add("GC");
	ShortForms.Add("POB");
	ShortForms.Add("LF");
	ShortForms.Add("SQ");
	ShortForms.Add("FF");
	ShortForms.Add("FPG");
	ShortForms.Add("MHP");
	ShortForms.Add("LPH");
	ShortForms.Add("AP");
	ShortForms.Add("NOTFDESCR");
	ShortForms.Add("NPF");
	ShortForms.Add("PKF");
	ShortForms.Add("PCP");
	ShortForms.Add("PKK");
	ShortForms.Add("CF");
	ShortForms.Add("TF");
	ShortForms.Add("SD");
	ShortForms.Add("D(From1)U");
	ShortForms.Add("TFPG");
	ShortForms.Add("MFPG");
	ShortForms.Add("D/From1");
	ShortForms.Add("B-CA");
	ShortForms.Add("P-KA");
	ShortForms.Add("A-KA");
	ShortForms.Add("Z1-D");
	ShortForms.Add("ADOK");
	ShortForms.Add("MediaEd");
	ShortForms.Add("PrT");
	ShortForms.Add("APAOOT");
	ShortForms.Add("CJSC1");
	ShortForms.Add("APTOO");
	ShortForms.Add("APST");
	ShortForms.Add("APPT");
	ShortForms.Add("OPAOOT");
	ShortForms.Add("OPAOZT");
	ShortForms.Add("OPTOO");
	ShortForms.Add("OPST");
	ShortForms.Add("OPPT");
	ShortForms.Add("ASKFH");
	ShortForms.Add("KFHUNION");
	ShortForms.Add("POBUNION");
	ShortForms.Add("In_-t");
	ShortForms.Add("RSU");
	ShortForms.Add("CORP");
	ShortForms.Add("Comp");
	ShortForms.Add("B-ka");
	ShortForms.Add("BSP");
	ShortForms.Add("CRB");
	ShortForms.Add("MUUC");
	ShortForms.Add("MSC");
	ShortForms.Add("CRBUH");
	ShortForms.Add("CBUH");
	ShortForms.Add("FINANCEDEPARTMENT");
	ShortForms.Add("KC");
	ShortForms.Add("PROFCOM");
	ShortForms.Add("ATP");
	ShortForms.Add("PATP");
	ShortForms.Add("CDN");
	ShortForms.Add("NOTP");
	ShortForms.Add("NOTK");
	ShortForms.Add("Z2/From1");
	ShortForms.Add("DEP");
	ShortForms.Add("RW");
	ShortForms.Add("COOP");
	Return ShortForms;
	
EndFunction	

////////////////////////////////////////////////////////////////////////////////
// Implementation of the event OnDetermineAdditionalCompanyInfo.

Function PictureFromFile(FileRef) Export
	
	BinaryData = Undefined;
	
	If ValueIsFilled(FileRef) And Not FileRef.IsEmpty() Then
		BinaryData = FilesOperations.FileBinaryData(FileRef, False);
	EndIf;
	
	If BinaryData = Undefined Then
		Return New Picture;
	EndIf;
	
	Return New Picture(BinaryData, True);
	
EndFunction

// Runs from the FillingProcessing event of demo document object modules.
//
// Parameters:
//  Object - CatalogObject
//         - DocumentObject - Object to populate.
//  AttributeName - String - Company attribute name.
//
Procedure OnEnterNewItemFillCompany(Object, AttributeName = "Organization") Export
	Query = New Query;
	Query.Text =
	"SELECT ALLOWED
	|	Companies.Ref AS Organization
	|FROM
	|	Catalog._DemoCompanies AS Companies
	|		INNER JOIN Constant._DemoMainCompany AS _DemoMainCompany
	|		ON Companies.Ref = _DemoMainCompany.Value";
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Object[AttributeName] = Selection.Organization;
	EndIf;
EndProcedure

Function SchemeDataPrintsLastNameInitials()
	
	FieldList = PrintManagement.PrintDataFieldTable();
	
	Field = FieldList.Add();
	Field.Id = "Ref";
	Field.Presentation = NStr("ru = 'Ссылка';
								|en = 'Ref';");
	Field.ValueType = New TypeDescription();	

	Field = FieldList.Add();
	Field.Id = "InitialsAndLastName";
	Field.Presentation = NStr("ru = 'Фамилия И. О.';
								|en = 'Name Surname';");
	Field.ValueType = New TypeDescription("String");
	
	Return PrintManagement.SchemaCompositionDataPrint(FieldList);
	
EndFunction


Function SchemaPrintDataBarcodes()
	
	FieldList = PrintManagement.PrintDataFieldTable();
	
	Field = FieldList.Add();
	Field.Id = "Ref";
	
	Field = FieldList.Add();
	Field.Id = "BarcodeIcon";
	Field.Presentation = NStr("ru = 'Картинка штрихкода';
								|en = 'Barcode picture';");
	Field.Picture = PictureLib.TypePicture;
	
	Return PrintManagement.SchemaCompositionDataPrint(FieldList);
	
EndFunction

Function PrintDataBarcodes(DataSources)
	DataSet = New ValueTable();
	DataSet.Columns.Add("Ref");
	DataSet.Columns.Add("BarcodeIcon");
	
	For Each DataSource In DataSources Do
		DataFieldsVal = DataSet.Add();  
		DataFieldsVal.Ref = DataSource; 
		
		BarcodeParameters = BarcodeGeneration.BarcodeGenerationParameters();
		BarcodeParameters.CodeType = 1;
		BarcodeParameters.Width = 242;
		BarcodeParameters.Height = 127;
		BarcodeParameters.Barcode = DataSource;
		
		DataFieldsVal.BarcodeIcon = BarcodeGeneration.TheImageOfTheBarcode(BarcodeParameters).Picture;
	EndDo;
	
	Return DataSet;
	
EndFunction

#EndRegion


