#Region Internal

// Returns the description of an additional property value type by name.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  TypeName	- String - Name of the additional property value type.
// 
// Returns:
//  TypeDescription - Value data type details.
Function ValueTypeOfAdditionalPropertyByName(TypeName) Export

	If TypeName = "string" Then
		Return New TypeDescription("String");
	ElsIf TypeName = "decimal" Then
		Return New TypeDescription("Number");
	ElsIf TypeName = "date" Then
		Return New TypeDescription("Date",,,,, DateFractions.DateTime);
	ElsIf TypeName = "boolean" Then
		Return New TypeDescription("Boolean");
	ElsIf TypeName = "subscriber" Then
		Return New TypeDescription("Number",,, New NumberQualifiers(12, 0, AllowedSign.Nonnegative));
	ElsIf TypeName = "service" Then
		Return StringTypeDetails(9);
	ElsIf TypeName = "additional_value" Then
		Return StringTypeDetails(255);
	ElsIf TypeName = "additional_value_group" Then
		Return StringTypeDetails(255);
	ElsIf TypeName = "tariff" Then
		Return StringTypeDetails(9);
	ElsIf TypeName = "service_provider_tariff" Then
		Return StringTypeDetails(9);
	ElsIf TypeName = "user" Then
		Return StringTypeDetails(32);
	ElsIf TypeName = "tariff_period" Then
		Return StringTypeDetails(10);
	ElsIf TypeName = "subscription" Then
		Return StringTypeDetails(9);
	Else
		Return Type("Undefined");
	EndIf;

EndFunction

#EndRegion 

#Region Private

Function StringTypeDetails(StringLength)
	
	Return New TypeDescription("String", New StringQualifiers(StringLength, AllowedLength.Variable));
	
EndFunction

#EndRegion 