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

	Parameters.Filter.Property("Individual", FilterIndividual);
	SetDynamicListFilterItem(List, "Individual", FilterIndividual);

	Parameters.Filter.Property("Organization", FilterOrganization);
	SetDynamicListFilterItem(List, "Organization", FilterOrganization);

EndProcedure

////////////////////////////////////////////////////////////////////////////////
// FORM ITEM EVENT HANDLERS

&AtClient
Procedure FilterIndividualOnChange(Item)

	SetDynamicListFilterItem(List, "Individual", FilterIndividual);

EndProcedure

&AtClient
Procedure FilterOrganizationOnChange(Item)

	SetDynamicListFilterItem(List, "Organization", FilterOrganization);

EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure SetDynamicListFilterItem(Val DynamicList, Val FieldName, Val RightValue,
	Val Var_ComparisonType = Undefined)

	If Var_ComparisonType = Undefined Then
		Var_ComparisonType = DataCompositionComparisonType.Equal;
	EndIf;

	CommonClientServer.SetFilterItem(DynamicList.Filter, FieldName, RightValue,
		Var_ComparisonType,, ValueIsFilled(RightValue), DataCompositionSettingsItemViewMode.Inaccessible);

EndProcedure

#EndRegion