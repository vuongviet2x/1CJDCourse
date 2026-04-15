
&AtClient
Var PreviousObjectType;

&AtClient
Procedure ObjectOnChange(Item)
	
	TypeOfObject = TypeOf(Record.Object);

	If PreviousObjectType <> TypeOfObject Then
		Record.CharacteristicType  = Undefined;
		Record.CharacteristicValue = Undefined;
		SetChoiceParametersForCharacteristicType();
		
		PreviousObjectType = TypeOfObject;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If ValueIsFilled(Record.Object) Then
		Items.Object.Visible = False;
		SetChoiceParametersForCharacteristicType();
	EndIf;
	
EndProcedure

&AtServer
Procedure SetChoiceParametersForCharacteristicType()
		
	ChoiceParameters = New Array();
	
	If Record.Object <> Undefined Then
		NewLink = New ChoiceParameter("Filter.CharacteristicsObjectType", CharacteristicsObjectType());
		ChoiceParameters.Add(NewLink);
	EndIf;
	
	Items.CharacteristicType.ChoiceParameters = New FixedArray(ChoiceParameters);
	
EndProcedure

&AtServer
Function CharacteristicsObjectType()

	TypeOfObject = TypeOf(Record.Object);
	
	If TypeOfObject = Type("CatalogRef.Companies") Then
		Result = Enums.CharacteristicsObjectTypes.Companies;
	ElsIf TypeOfObject = Type("CatalogRef.Counterparties") Then
		Result = Enums.CharacteristicsObjectTypes.Counterparties;
	ElsIf TypeOfObject = Type("CatalogRef.CounterpartyContracts") Then
		Result = Enums.CharacteristicsObjectTypes.Contracts;
	ElsIf TypeOfObject = Type("CatalogRef.Products") Then
		Result = Enums.CharacteristicsObjectTypes.Products;
	ElsIf TypeOfObject = Type("CatalogRef.Warehouses") Then
		Result = Enums.CharacteristicsObjectTypes.Warehouses;
	Else
		Raise "Unexpected type of object: " + TypeOfObject;
	EndIf;

	Return Result;
	
EndFunction

