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

	ManualEdit = Parameters.ManualEdit;
	OwnerAttribute = Parameters.Attribute;
	OutOfBusiness = False;

	FieldValues = New Structure;
	If ManualEdit Then
		FieldValues = Parameters.FieldValues;
	Else
		Bank = Parameters.Bank;
		If TypeOf(Bank) = Type("CatalogRef.BankClassifier") And ValueIsFilled(Bank) Then
			FieldValues = Common.ObjectAttributesValues(Bank,
				"Code,CorrAccount,Description,City,Address,Phones,Parent,OutOfBusiness");
			BIC = FieldValues.Code;
			State = FieldValues.Parent;
			InClassifier = True;
			OutOfBusiness = FieldValues.OutOfBusiness;
		EndIf;
	EndIf;
	FillPropertyValues(ThisObject, FieldValues);

	Items.BankOperationsDiscontinuedLabel.Visible = OutOfBusiness;
	WindowOptionsKey = "BankOutOfBusiness=" + String(OutOfBusiness);

	ReadOnly = Not ManualEdit And InClassifier;

	If Common.IsMobileClient() Then
		ItemsAndTitlesAlign = ItemsAndTitlesAlignVariant.ItemsRightTitlesLeft;
		CommandBarLocation = FormCommandBarLabelLocation.Top;
	EndIf;

EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)

	Notification = New NotifyDescription("SelectAndClose", ThisObject);
	CommonClient.ShowFormClosingConfirmation(Notification, Cancel, Exit);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OkCommand(Command)

	SelectAndClose();

EndProcedure

&AtClient
Procedure CancelCommand(Command)

	Modified = False;
	Close();

EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SelectAndClose(Result = Undefined, AdditionalParameters = Undefined) Export

	Modified = False;
	NotifyChoice(GetParameterValues());

EndProcedure

&AtClient
Function GetParameterValues()

	Result = New Structure;
	Result.Insert("Attribute", OwnerAttribute);

	If ManualEdit Then
		Result.Insert("ManualEdit", ManualEdit);
		FieldValues = New Structure;
		FieldValues.Insert("BIC", BIC);
		FieldValues.Insert("Description", Description);
		FieldValues.Insert("CorrAccount", CorrAccount);
		FieldValues.Insert("City", City);
		FieldValues.Insert("Address", Address);
		FieldValues.Insert("Phones", Phones);
		FieldValues.Insert("ManualEdit", ManualEdit);

		Result.Insert("FieldValues", FieldValues);
	Else
		If InClassifier Then
			Result.Insert("ManualEdit", ManualEdit);
			Result.Insert("Bank", Bank);
		Else
			Result.Insert("ManualEdit", True);
			FieldValues = New Structure;
			FieldValues.Insert("BIC", BIC);
			FieldValues.Insert("Description", Description);
			FieldValues.Insert("CorrAccount", CorrAccount);
			FieldValues.Insert("City", City);
			FieldValues.Insert("Address", Address);
			FieldValues.Insert("Phones", Phones);
			FieldValues.Insert("ManualEdit", ManualEdit);

			Result.Insert("FieldValues", FieldValues);
		EndIf;
	EndIf;

	Return Result;

EndFunction

#EndRegion