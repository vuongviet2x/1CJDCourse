#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Returns enumeration value by value name.
//
// Parameters:
//  EnumValueName	- String - Value name as it is passed via API.
// 
// Returns:
//  EnumRef.SubscriberUsersRoles - Enumeration value by its name.
//
Function ValueByName(EnumValueName) Export
    
    If EnumValueName = "owner" Then
        Return PredefinedValue("Enum.SubscriberUsersRoles.SubscriberOwner");
    ElsIf EnumValueName = "administrator" Then
        Return PredefinedValue("Enum.SubscriberUsersRoles.SubscriberAdministrator");
    ElsIf EnumValueName = "operator" Then
        Return PredefinedValue("Enum.SubscriberUsersRoles.ServiceCompanyOperator");
    ElsIf EnumValueName = "user" Then
        Return PredefinedValue("Enum.SubscriberUsersRoles.SubscriberUser");
    ElsIf EnumValueName = "ext_administrator" Then
        Return PredefinedValue("Enum.SubscriberUsersRoles.AdaptationToolsAdministrator");
    Else
        Return PredefinedValue("Enum.SubscriberUsersRoles.EmptyRef");
    EndIf; 
    
EndFunction

// Returns a value name for API by enumeration value.
//
// Parameters:
//  Value - EnumRef.ApplicationUserRights - Enumeration value to get a value name for API.
// 
// Returns:
//  String - Value name for API.
//
Function NameByValue(Value) Export
	
    If Value = PredefinedValue("Enum.SubscriberUsersRoles.SubscriberOwner") Then
        Return "owner";
    ElsIf Value = PredefinedValue("Enum.SubscriberUsersRoles.SubscriberAdministrator") Then
        Return "administrator";
    ElsIf Value = PredefinedValue("Enum.SubscriberUsersRoles.ServiceCompanyOperator") Then
        Return "operator";
    ElsIf Value = PredefinedValue("Enum.SubscriberUsersRoles.SubscriberUser") Then
        Return "user";
    ElsIf Value = PredefinedValue("Enum.SubscriberUsersRoles.AdaptationToolsAdministrator") Then
        Return "ext_administrator";
    Else 
        Return Undefined;
    EndIf; 
	
EndFunction

#EndRegion

#EndIf