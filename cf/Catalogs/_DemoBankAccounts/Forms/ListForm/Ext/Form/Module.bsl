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

	SetConditionalAppearance();

	If Parameters.OpenFromFormMode Then
		Items.Owner.Visible = False;
	EndIf;

	SwitchAccountsVisibilityInInactiveBanks(False);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ShowAccountsInInactiveBanks(Command)
	SwitchAccountsVisibilityInInactiveBanks(Not Items.FormShowAccountsInInactiveBanks.Check);
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SwitchAccountsVisibilityInInactiveBanks(Visible)

	Items.FormShowAccountsInInactiveBanks.Check = Visible;

	CommonClientServer.SetDynamicListFilterItem(
			List, "BankOutOfBusiness", False,,, Not Visible);

EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	List.ConditionalAppearance.Items.Clear();
	Item = List.ConditionalAppearance.Items.Add();

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("BankOutOfBusiness");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);

EndProcedure

#EndRegion