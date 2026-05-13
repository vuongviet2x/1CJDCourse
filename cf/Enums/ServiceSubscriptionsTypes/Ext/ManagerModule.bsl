#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Returns enumeration value by name of the service API property value.
//
// Parameters:
//  EnumValueName - String - Property name value.
// 
// Returns:
//   EnumRef.ServiceSubscriptionsTypes - an enumeration value.
//
Function ValueByName(EnumValueName) Export
	
	If EnumValueName = "basic" Then
		Return PredefinedValue("Enum.ServiceSubscriptionsTypes.Main");
	ElsIf EnumValueName = "prolonging" Then
		Return PredefinedValue("Enum.ServiceSubscriptionsTypes.Prolonging");
	ElsIf EnumValueName = "extending" Then
		Return PredefinedValue("Enum.ServiceSubscriptionsTypes.Extending");
	Else
		Return PredefinedValue("Enum.ServiceSubscriptionsTypes.EmptyRef");
	EndIf; 
	
EndFunction

#EndRegion

#EndIf