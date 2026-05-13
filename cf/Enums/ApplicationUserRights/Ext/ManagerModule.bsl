#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Returns enumeration value by value name in API.
//
// Parameters:
//  EnumValueName	- String - Value name as it is passed via API.
// 
// Returns:
//  EnumRef.ApplicationUserRights - Enumeration value by its name.
//
Function ValueByName(EnumValueName) Export
    
    If EnumValueName = "user" Then
        Return PredefinedValue("Enum.ApplicationUserRights.Run");
    ElsIf EnumValueName = "administrator" Then
        Return PredefinedValue("Enum.ApplicationUserRights.StartAndAdministration");
    ElsIf EnumValueName = "api" Then
        Return PredefinedValue("Enum.ApplicationUserRights.APIAccess");
    Else
        Return PredefinedValue("Enum.ApplicationUserRights.EmptyRef");
    EndIf; 
    
EndFunction

// Returns a value name for API by enumeration value.
//
// Parameters:
//  Value - EnumRef.ApplicationUserRights - Enumeration value to get its name for API.
// 
// Returns:
//  String - Value name for API.
//
Function NameByValue(Value) Export
	
    If Value = PredefinedValue("Enum.ApplicationUserRights.Run") Then
        Return "user";
    ElsIf Value = PredefinedValue("Enum.ApplicationUserRights.StartAndAdministration") Then
        Return "administrator";
    ElsIf Value = PredefinedValue("Enum.ApplicationUserRights.APIAccess") Then
        Return "api";
    Else 
        Return Undefined;
    EndIf; 
	
EndFunction

#EndRegion

#EndIf