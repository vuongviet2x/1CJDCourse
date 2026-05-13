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
Var RefreshInterface;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Update items states.
	SetAvailability();
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	If Exit Then
		Return;
	EndIf;
	RefreshApplicationInterface();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure MainCompanyOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

&AtClient
Procedure MainCompanyClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure UseMultipleCompaniesOnChange(Item)
	Attachable_OnChangeAttribute(Item);
EndProcedure

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Client.

&AtClient
Procedure Attachable_OnChangeAttribute(Item, ShouldRefreshInterface = True)
	
	ConstantName = OnChangeAttributeServer(Item.Name);
	RefreshReusableValues();
	
	If ShouldRefreshInterface Then
		RefreshInterface = True;
		AttachIdleHandler("RefreshApplicationInterface", 2, True);
	EndIf;
	
	If ConstantName <> "" Then
		Notify("Write_ConstantsSet", New Structure, ConstantName);
	EndIf;
	
EndProcedure

&AtClient
Procedure RefreshApplicationInterface()
	
	If RefreshInterface = True Then
		RefreshInterface = False;
		CommonClient.RefreshApplicationInterface();
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Server call.

&AtServer
Function OnChangeAttributeServer(TagName)
	
	DataPathAttribute = Items[TagName].DataPath;
	ConstantName = SaveAttributeValue(DataPathAttribute);
	SetAvailability(DataPathAttribute);
	RefreshReusableValues();
	Return ConstantName;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Server.

&AtServer
Function SaveAttributeValue(DataPathAttribute)
	
	NameParts = StrSplit(DataPathAttribute, ".");
	If NameParts.Count() <> 2 Then
		Return "";
	EndIf;
	
	ConstantName = NameParts[1];
	ConstantManager = Constants[ConstantName];
	ConstantValue = ConstantsSet[ConstantName];
	
	If ConstantManager.Get() <> ConstantValue Then
		ConstantManager.Set(ConstantValue);
	EndIf;
	
	Return ConstantName;
	
EndFunction

&AtServer
Procedure SetAvailability(DataPathAttribute = "")
	
	NumberOfOrganizations = Catalogs._DemoCompanies.NumberOfOrganizations();
	
	If DataPathAttribute = "ConstantsSet._DemoUseMultipleCompanies" Or DataPathAttribute = "" Then
		// Cannot clear the checkbox after a second company is created.
		Items.UseMultipleCompanies.Enabled = Not (NumberOfOrganizations > 1 And ConstantsSet._DemoUseMultipleCompanies);
	EndIf;
	
	If DataPathAttribute = "ConstantsSet._DemoMainCompany"
		Or DataPathAttribute = "ConstantsSet._DemoUseMultipleCompanies"
		Or DataPathAttribute = "" Then
		
		// Cannot change the main company unless multi-company accounting is disabled.
		Items.MainCompany.ReadOnly = Not ConstantsSet._DemoUseMultipleCompanies
			And ValueIsFilled(ConstantsSet._DemoMainCompany);
		
		// A new company can be added in the following cases:
		//   - There are no companies yet.
		//   - Multi-company accounting is enabled.
		Items.MainCompany.CreateButton = NumberOfOrganizations = 0
			Or ConstantsSet._DemoUseMultipleCompanies;
		
		// A company can be selected in the following cases:
		//   - This company is not selected.
		//   - Multi-company accounting is enabled.
		Items.MainCompany.ChoiceButton = Not ValueIsFilled(ConstantsSet._DemoMainCompany)
			Or ConstantsSet._DemoUseMultipleCompanies;
		
		// Show quick choice list only if there are creation or selection buttons.
		Items.MainCompany.DropListButton = Items.MainCompany.CreateButton
			Or Items.MainCompany.ChoiceButton;
		
	EndIf;
	
EndProcedure

#EndRegion
