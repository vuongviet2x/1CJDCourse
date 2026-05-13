///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Variables

&AtClient
Var TheNameOfThePropertyToEdit;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Object.ManualBankDetailsChange Then
		BankBIC		  = Object.BankBIC;
		BankDescription = Object.BankDescription;
		BankCorrAccount	  = Object.BankCorrAccount;
		BankCity		  = Object.BankCity;
		SWIFTBIC = Object.SWIFTBIC;
	Else
		If Not Object.Bank.IsEmpty() Then
			FillInBankDetailsByBank(Object.Bank, "Bank", False);
		EndIf;
	EndIf;

	If ValueIsFilled(Object.Ref) Then
		If (ValueIsFilled(Object.TransferBankBIC)) Or (ValueIsFilled(Object.TransferBank))
			Or ValueIsFilled(Object.PaymentSWIFTBIC) Then
			SettlementBankUsed = True;
		Else
			SettlementBankUsed = False;
		EndIf;
	EndIf;

	If Object.TransferBankDetailsManualEdit Then
		TransferBankBIC			 = Object.TransferBankBIC;
		TransferBankDescription = Object.TransferBankDescription;
		TransferBankCorrAccount	 = Object.TransferBankCorrAccount;
		TransferBankCity		 = Object.TransferBankCity;
		PaymentSWIFTBIC = Object.PaymentSWIFTBIC;
	Else
		If Not Object.TransferBank.IsEmpty() Then
			FillInBankDetailsByBank(Object.TransferBank, "TransferBank", False);
		EndIf;
	EndIf;

	NationalCurrency = Catalogs.Currencies.FindByCode("643");
	BankDetailsAcquisitionMethod = ?(Object.ManualBankDetailsChange, "Manually", "FromClassifier");
	SettlementBankDetailsAcquisitionMethod = ?(Object.TransferBankDetailsManualEdit, "Manually",
		"FromClassifier");
	AccountOpeningLocation = ?(Object.Foreign, "Foreign1", "RF");

	UpdateBankInactivityNoteText();
	FormItemsManagement(ThisObject);

	If Common.IsMobileClient() Then
		ItemsAndTitlesAlign = ItemsAndTitlesAlignVariant.ItemsRightTitlesLeft;
	EndIf;

EndProcedure

&AtClient
Procedure ChoiceProcessing(SelectionResult, ChoiceSource)

	If Upper(ChoiceSource.FormName) = Upper("Catalog._DemoBankAccounts.Form.BankingDetails") Then
		SetBankDetails(SelectionResult);
	ElsIf Upper(ChoiceSource.FormName) = Upper("Catalog.BankClassifier.Form.ChoiceForm") Then
		SelectBank(SelectionResult);
	EndIf;

	If Window <> Undefined Then
		Window.Activate();
	EndIf;

	UpdateBankInactivityNoteText();
	FormItemsManagement(ThisObject);

EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)

	If Object.ManualBankDetailsChange Then
		Object.BankBIC			 = BankBIC;
		Object.BankCorrAccount	 = BankCorrAccount;
		Object.BankDescription = BankDescription;
		Object.BankCity		 = BankCity;
		Object.SWIFTBIC = SWIFTBIC;
	Else
		Object.BankBIC			 = "";
		Object.BankCorrAccount	 = "";
		Object.BankDescription = "";
		Object.BankCity		 = "";
		Object.SWIFTBIC = "";
	EndIf;

	If SettlementBankUsed And Object.TransferBankDetailsManualEdit Then
		Object.TransferBankBIC			= TransferBankBIC;
		Object.TransferBankCorrAccount		= TransferBankCorrAccount;
		Object.TransferBankDescription = TransferBankDescription;
		Object.TransferBankCity		= TransferBankCity;
		Object.PaymentSWIFTBIC = PaymentSWIFTBIC;
	Else
		Object.TransferBankBIC			= "";
		Object.TransferBankCorrAccount		= "";
		Object.TransferBankDescription = "";
		Object.TransferBankCity		= "";
		Object.PaymentSWIFTBIC = "";
	EndIf;

	Object.Foreign = AccountOpeningLocation = "Foreign1";

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.AccessManagement

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SettlementBankUsedOnChange(Item)

	FormItemsManagement(ThisObject);

EndProcedure

&AtClient
Procedure OwnerOnChange(Item)
	FormItemsManagement(ThisObject);
EndProcedure

&AtClient
Procedure BankBICStartChoice(Item, ChoiceData, StandardProcessing)
	TheNameOfThePropertyToEdit = "BankBIC";
	BankDetailsWhenSelecting("BankBIC", ThisObject);
EndProcedure

&AtClient
Procedure BankBICOpening(Item, StandardProcessing)
	TheNameOfThePropertyToEdit = "BankBIC";
	StandardProcessing = False;
	OtkritieBankDetails("BankBIC");
EndProcedure

&AtClient
Procedure SettlementBankBICStartChoice(Item, ChoiceData, StandardProcessing)
	TheNameOfThePropertyToEdit = "TransferBankBIC";
	BankDetailsWhenSelecting("TransferBankBIC", ThisObject);
EndProcedure

&AtClient
Procedure SettlementBankBICOpening(Item, StandardProcessing)
	TheNameOfThePropertyToEdit = "TransferBankBIC";
	StandardProcessing = False;
	OtkritieBankDetails("TransferBankBIC");
EndProcedure

&AtClient
Procedure AccountOpeningLocationOnChange(Item)
	Object.Foreign = AccountOpeningLocation = "Foreign1";
	Object.ManualBankDetailsChange = True;
	FormItemsManagement(ThisObject);
EndProcedure

&AtClient
Procedure CurrencyOnChange(Item)
	Object.TransferBankDetailsManualEdit = Object.Currency <> NationalCurrency;
	FormItemsManagement(ThisObject);
EndProcedure

&AtClient
Procedure SettlementBankDetailsAcquisitionMethodOnChange(Item)
	Object.TransferBankDetailsManualEdit = SettlementBankDetailsAcquisitionMethod = "Manually";
	If Not Object.TransferBankDetailsManualEdit Then
		FillInBankDetailsForBIC(TransferBankBIC, "TransferBank", True);
	EndIf;
	FormItemsManagement(ThisObject);
EndProcedure

&AtClient
Procedure BankDetailsAcquisitionMethodOnChange(Item)
	Object.ManualBankDetailsChange = BankDetailsAcquisitionMethod = "Manually";
	If Not Object.ManualBankDetailsChange Then
		FillInBankDetailsForBIC(BankBIC, "Bank", True);
	EndIf;
	FormItemsManagement(ThisObject);
EndProcedure

#EndRegion

#Region Private

&AtServer
Function FillInBankDetailsForBIC(BIC, BankType, TransferBankingDetailsValues = False)

	InformationAboutTheBank = BankManager.BICInformation(BIC);
	Result = InformationAboutTheBank.Count() > 0;
	If BankType = "Bank" Then

		BankBIC		  = "";
		BankCorrAccount	  = "";
		BankDescription = "";
		BankCity		  = "";

		If Not Result Then
			Return Result;
		EndIf;

		RecordAboutBank      = InformationAboutTheBank[0].Ref.GetObject();
		BankBIC          = RecordAboutBank.Code;
		BankCorrAccount     = RecordAboutBank.CorrAccount;
		BankDescription = RecordAboutBank.Description;
		BankCity        = RecordAboutBank.City;
		FoundByBIC        = True;
		SWIFTBIC = RecordAboutBank.SWIFTBIC;
		If TransferBankingDetailsValues Then
			Object.BankBIC          = "";
			Object.BankDescription = "";
			Object.BankCorrAccount     = "";
			Object.BankCity        = "";
			Object.BankAddress        = "";
			Object.BankPhones     = "";
			Object.Bank              = RecordAboutBank.Ref;
		EndIf;
		BankOutOfBusiness = Not Object.ManualBankDetailsChange And BankOutOfBusiness(BankBIC);
		
	ElsIf BankType = "TransferBank" Then
		TransferBankBIC          = "";
		TransferBankCorrAccount     = "";
		TransferBankDescription = "";
		TransferBankCity        = "";

		If Result Then
			RecordAboutBank = InformationAboutTheBank[0].Ref.GetObject();
			TransferBankBIC          = RecordAboutBank.Code;
			TransferBankCorrAccount     = RecordAboutBank.CorrAccount;
			TransferBankDescription = RecordAboutBank.Description;
			TransferBankCity        = RecordAboutBank.City;
			PaymentSWIFTBIC = RecordAboutBank.SWIFTBIC;
			FoundByBIC                   = True;
			If TransferBankingDetailsValues Then
				Object.TransferBankBIC          = "";
				Object.TransferBankDescription = "";
				Object.TransferBankCorrAccount     = "";
				Object.TransferBankCity        = "";
				Object.TransferBankAddress        = "";
				Object.TransferBankPhones     = "";
				Object.TransferBank              = RecordAboutBank.Ref;
			EndIf;
		EndIf;
		IntermediaryBankOperationsDiscontinued = Not Object.TransferBankDetailsManualEdit
			And BankOutOfBusiness(TransferBankBIC);
	EndIf;

	UpdateBankInactivityNoteText();

	Return Result;
	
EndFunction

&AtServer
Procedure FillInBankDetailsByBank(Bank, BankType, TransferBankingDetailsValues = False)
	If BankType = "Bank" Then
		BankBIC          = Bank.Code;
		BankCorrAccount     = Bank.CorrAccount;
		BankDescription = Bank.Description;
		BankCity        = Bank.City;
		SWIFTBIC = Bank.SWIFTBIC;
		If TransferBankingDetailsValues Then
			Object.BankBIC          = Bank.Code;
			Object.BankDescription = Bank.Description;
			Object.BankCorrAccount     = Bank.CorrAccount;
			Object.BankCity        = Bank.City;
			Object.BankAddress        = Bank.Address;
			Object.BankPhones     = Bank.Phones;
			Object.Bank              = "";
			Object.SWIFTBIC = Bank.SWIFTBIC;
		EndIf;
		BankOutOfBusiness = Not Object.ManualBankDetailsChange And BankOutOfBusiness(BankBIC);
	ElsIf BankType = "TransferBank" Then
		TransferBankBIC			 = Bank.Code;
		TransferBankCorrAccount	 = Bank.CorrAccount;
		TransferBankDescription = Bank.Description;
		TransferBankCity		 = Bank.City;
		PaymentSWIFTBIC = Bank.SWIFTBIC;
		If TransferBankingDetailsValues Then
			Object.TransferBankBIC          = Bank.Code;
			Object.TransferBankDescription = Bank.Description;
			Object.TransferBankCorrAccount     = Bank.CorrAccount;
			Object.TransferBankCity        = Bank.City;
			Object.TransferBankAddress        = Bank.Address;
			Object.TransferBankPhones     = Bank.Phones;
			Object.TransferBank              = "";
			Object.PaymentSWIFTBIC = Bank.PaymentSWIFTBIC;
		EndIf;
		IntermediaryBankOperationsDiscontinued = Not Object.TransferBankDetailsManualEdit
			And BankOutOfBusiness(TransferBankBIC);
	EndIf;
EndProcedure

&AtClientAtServerNoContext
Procedure FormItemsManagement(Form)

	Items = Form.Items;
	Object = Form.Object;

	Form.BankDetailsAcquisitionMethod = ?(Object.ManualBankDetailsChange, "Manually", "FromClassifier");
	Form.SettlementBankDetailsAcquisitionMethod = ?(Object.TransferBankDetailsManualEdit, "Manually",
		"FromClassifier");

	ThisIsTheOrganizationSAccount = (TypeOf(Object.Owner) = Type("CatalogRef._DemoCompanies"));
	ForeignAccount = Object.Foreign;

	Items.PrintSettingsPage.Visible = ThisIsTheOrganizationSAccount;
	Items.AccountDetails.PagesRepresentation = ?(ThisIsTheOrganizationSAccount, FormPagesRepresentation.TabsOnTop,
		FormPagesRepresentation.None);
	Items.SettlementBankGroup.Enabled = Form.SettlementBankUsed;
	Items.BankDetailsAcquisitionMethod.Enabled = Not ForeignAccount;

	Items.BankingDetails.Enabled = Object.ManualBankDetailsChange;
	Items.SettlementBankDetails.Enabled = Object.TransferBankDetailsManualEdit;

	Items.SettlementBankDetailsAcquisitionMethod.Enabled = Object.Currency = Form.NationalCurrency;

	Items.BankingDetails.Enabled = Object.ManualBankDetailsChange;
	Items.SettlementBankDetails.Enabled = Object.TransferBankDetailsManualEdit;

	Items.BankStatus.CurrentPage = ?(Form.BankOutOfBusiness, Items.BankClosed,
		Items.BankOperates);

	Items.IntermediaryBankStatus.CurrentPage = ?(Form.IntermediaryBankOperationsDiscontinued,
		Items.IntermediaryBankClosed, Items.IntermediaryBankOperates);

	If Not Object.Foreign Then
		Items.BankCodes.CurrentPage = Items.BankCodesRussianAccount;
	Else
		Items.BankCodes.CurrentPage = Items.BankCodesForeignAccount;
	EndIf;

	If Object.Currency = Form.NationalCurrency Then
		Items.SettlementBankCodes.CurrentPage = Items.SettlementBankCodesForAccountInRubles;
	Else
		Items.SettlementBankCodes.CurrentPage = Items.SettlementBankCodesForCurrencyAccount;
	EndIf;

EndProcedure

&AtClient
Procedure BankDetailsWhenSelecting(TagName, Form)
	If TagName = "BankBIC" Then
		If Not Object.ManualBankDetailsChange Then
			ParametersStructure = New Structure;
			ParametersStructure.Insert("Attribute", TagName);
			OpenForm("Catalog.BankClassifier.ChoiceForm", ParametersStructure, Form);
		EndIf;
	ElsIf TagName = "TransferBankBIC" Then
		If Not Object.TransferBankDetailsManualEdit Then
			ParametersStructure = New Structure;
			ParametersStructure.Insert("Attribute", TagName);
			OpenForm("Catalog.BankClassifier.ChoiceForm", ParametersStructure, Form);
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure OtkritieBankDetails(TagName)

	ParametersStructure = New Structure;
	ParametersStructure.Insert("Attribute", TagName);
	ParameterValues = New Structure;

	If TagName = "BankBIC" Then

		ParametersStructure.Insert("ManualEdit", Object.ManualBankDetailsChange);

		If Object.ManualBankDetailsChange Then
			ParameterValues.Insert("BIC", BankBIC);
			ParameterValues.Insert("Description", BankDescription);
			ParameterValues.Insert("CorrAccount", BankCorrAccount);
			ParameterValues.Insert("City", BankCity);
			ParameterValues.Insert("Address", Object.BankAddress);
			ParameterValues.Insert("Phones", Object.BankPhones);
		Else
			ParametersStructure.Insert("Bank", Object.Bank);
		EndIf;

	ElsIf TagName = "TransferBankBIC" Then

		ParametersStructure.Insert("ManualEdit", Object.TransferBankDetailsManualEdit);

		If Object.TransferBankDetailsManualEdit Then
			ParameterValues.Insert("BIC", TransferBankBIC);
			ParameterValues.Insert("Description", TransferBankDescription);
			ParameterValues.Insert("CorrAccount", TransferBankCorrAccount);
			ParameterValues.Insert("City", TransferBankCity);
			ParameterValues.Insert("Address", Object.TransferBankAddress);
			ParameterValues.Insert("Phones", Object.TransferBankPhones);
		Else
			ParametersStructure.Insert("Bank", Object.TransferBank);
		EndIf;

	EndIf;

	ParametersStructure.Insert("FieldValues", ParameterValues);
	OpenForm("Catalog._DemoBankAccounts.Form.BankingDetails", ParametersStructure, ThisObject);

EndProcedure

&AtClient
Procedure SelectBank(Val SelectionResult)

	If TypeOf(SelectionResult) <> Type("CatalogRef.BankClassifier") Then
		Return;
	EndIf;

	If TheNameOfThePropertyToEdit = "BankBIC" Then
		Object.Bank				 = SelectionResult;
		Object.BankBIC			 = "";
		Object.BankDescription = "";
		Object.BankCorrAccount	 = "";
		Object.BankCity		 = "";
		Object.BankAddress		 = "";
		Object.BankPhones	 = "";

		FillInBankDetailsByBank(SelectionResult, "Bank", False);
	ElsIf TheNameOfThePropertyToEdit = "TransferBankBIC" Then
		Object.TransferBank				= SelectionResult;
		Object.TransferBankBIC			= "";
		Object.TransferBankDescription = "";
		Object.TransferBankCorrAccount		= "";
		Object.TransferBankCity		= "";
		Object.TransferBankAddress		= "";
		Object.TransferBankPhones		= "";

		FillInBankDetailsByBank(SelectionResult, "TransferBank", False);
	EndIf;

EndProcedure

// Parameters:
//   SelectionResult - Structure:
//   * FieldValues - Structure
//
&AtClient
Procedure SetBankDetails(Val SelectionResult)

	If IsBlankString(SelectionResult) Then
		Return;
	EndIf;

	If SelectionResult.Attribute = "BankBIC" Then
		Object.ManualBankDetailsChange = SelectionResult.ManualEdit;
		BankDetailsAcquisitionMethod = ?(Object.ManualBankDetailsChange, "Manually", "FromClassifier");
		If SelectionResult.ManualEdit Then
			Object.Bank				 = "";
			Object.BankBIC			 = SelectionResult.FieldValues.BIC;
			Object.BankDescription = SelectionResult.FieldValues.Description;
			Object.BankCorrAccount	 = SelectionResult.FieldValues.CorrAccount;
			Object.BankCity		 = SelectionResult.FieldValues.City;
			Object.BankAddress		 = SelectionResult.FieldValues.Address;
			Object.BankPhones	 = SelectionResult.FieldValues.Phones;

			BankBIC		  = SelectionResult.FieldValues.BIC;
			BankCorrAccount	  = SelectionResult.FieldValues.CorrAccount;
			BankDescription = SelectionResult.FieldValues.Description;
			BankCity		  = SelectionResult.FieldValues.City;
		Else
			Object.Bank				 = SelectionResult.Bank;
			Object.BankBIC			 = "";
			Object.BankDescription = "";
			Object.BankCorrAccount	 = "";
			Object.BankCity		 = "";
			Object.BankAddress		 = "";
			Object.BankPhones	 = "";

			FillInBankDetailsByBank(Object.Bank, "Bank", False);
		EndIf;
	ElsIf SelectionResult.Attribute = "TransferBankBIC" Then
		Object.TransferBankDetailsManualEdit = SelectionResult.ManualEdit;
		SettlementBankDetailsAcquisitionMethod = ?(Object.TransferBankDetailsManualEdit, "Manually",
			"FromClassifier");
		If SelectionResult.ManualEdit Then
			Object.TransferBank				= "";
			Object.TransferBankBIC			= SelectionResult.FieldValues.BIC;
			Object.TransferBankDescription = SelectionResult.FieldValues.Description;
			Object.TransferBankCorrAccount		= SelectionResult.FieldValues.CorrAccount;
			Object.TransferBankCity		= SelectionResult.FieldValues.City;
			Object.TransferBankAddress		= SelectionResult.FieldValues.Address;
			Object.TransferBankPhones		= SelectionResult.FieldValues.Phones;

			TransferBankBIC			 = SelectionResult.FieldValues.BIC;
			TransferBankCorrAccount	 = SelectionResult.FieldValues.CorrAccount;
			TransferBankDescription = SelectionResult.FieldValues.Description;
			TransferBankCity		 = SelectionResult.FieldValues.City;
		Else
			Object.TransferBank				= SelectionResult.Bank;
			Object.TransferBankBIC			= "";
			Object.TransferBankDescription = "";
			Object.TransferBankCorrAccount		= "";
			Object.TransferBankCity		= "";
			Object.TransferBankAddress		= "";
			Object.TransferBankPhones		= "";

			FillInBankDetailsByBank(Object.TransferBank, "TransferBank", False);
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure BankDetailOnChange(Item)

	BankType = "Bank";
	ManualBankDetailsChange = Object.ManualBankDetailsChange;
	TheNameOfThePropertyToEdit = "BankBIC";

	If StrStartsWith(Item.Name, "TransferBankBIC") Then
		BankType = "TransferBank";
		ManualBankDetailsChange = Object.TransferBankDetailsManualEdit;
		TheNameOfThePropertyToEdit = "TransferBankBIC";
	EndIf;

	If ManualBankDetailsChange Then
		Return;
	EndIf;

	If FillInBankDetailsForBIC(ThisObject[TheNameOfThePropertyToEdit], BankType, True) Then
		FormItemsManagement(ThisObject);
		Return;
	EndIf;

	BIC = ThisObject[Item.Name];
	BankManagerClient.SelectFromTheBICDirectory(BIC, ThisObject);

EndProcedure

&AtServerNoContext
Function BankOutOfBusiness(BIC)

	Result = False;

	QueryText =
	"SELECT
	|	BankClassifier.OutOfBusiness
	|FROM
	|	Catalog.BankClassifier AS BankClassifier
	|WHERE
	|	BankClassifier.Code = &BIC
	|	AND BankClassifier.IsFolder = FALSE";

	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("BIC", BIC);

	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Result = Selection.OutOfBusiness;
	EndIf;

	Return Result;

EndFunction

&AtServer
Procedure UpdateBankInactivityNoteText()
	Items.BankOperationsDiscontinuedLabel.Title = BankManager.InvalidBankNote(Object.Bank);
	Items.SettlementBankOperationsDiscontinuedLabel.Title =BankManager.InvalidBankNote(
		Object.TransferBank);
EndProcedure

#EndRegion