///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

// Returns a structure of localizable attributes.
// 
// Parameters:
//  AttributesList - MetadataObjectCollection
//  MetadataSource - MetadataObjectCatalog, Undefined, MetadataObjectTabularSection - Common attributes
//      or tabular section metadata.
// 
// Returns:
//  Structure
//
Function GetAttributesToLocalize(AttributesList, MetadataSource = Undefined)
	
	AttributesToLocalize = New Structure;
	UseMetadata = Metadata.ObjectProperties.CommonAttributeUse.Use;
	
	If Languages.Count() = 1 Then
		Return AttributesToLocalize;
	EndIf;
	
	For Each Attribute In AttributesList Do
		
		If Not MetadataSource = Undefined And Not Attribute.Content.Find(MetadataSource).Use = UseMetadata Then
			Continue;
		EndIf;
		
		AttributeParameters = New Structure("Name, Type");
		FillPropertyValues(AttributeParameters, Attribute);
		
		If Not StrEndsWith(Attribute.Name, "Language1") Then
			Continue;
		EndIf;
		
		AttributesToLocalize.Insert(StrReplace(Attribute.Name, "Language1", ""), AttributeParameters);
		
	EndDo;
	
	Return AttributesToLocalize;
	
EndFunction

// Parameters:
//   ObjectMetadata - MetadataObjectCatalog
//   TabularSection - Boolean
//   HasGroups - Boolean
// Returns:
//   Structure
// 
Function GetMetadataObjectAttributes(ObjectMetadata, KeyAttributeName, TabularSection = False, HasGroups = False) Export
	
	ObjectStructure = New Structure;
	HasGroups = ?(TabularSection, HasGroups, False);
	StringType = Type("String");
	
	If TabularSection Then
		AttributesToLocalize = GetAttributesToLocalize(ObjectMetadata.Attributes);
	Else
		AttributesToLocalize = GetAttributesToLocalize(Metadata.CommonAttributes, ObjectMetadata);
		
		For Each Attribute In ObjectMetadata.StandardAttributes Do
			
			If StrFind("IsFolder", Attribute.Name) > 0 Then
				HasGroups = True;
				Continue;
			ElsIf StrFind("Ref, Predefined, DeletionMark, IsFolder", Attribute.Name) > 0 Then
				Continue;
			EndIf;
			
			AttributeStructure = InitializeAttributeStructure();
			AttributeStructure.ValueType  = Attribute.Type;
			AttributeStructure.IsExcludable  = AttributeIsExcluded(Attribute, ObjectMetadata);
			AttributeStructure.ToLocalize = AttributesToLocalize.Property(Attribute.Name);
			AttributeStructure.AttributeString    = Not AttributeStructure.ToLocalize
				And Not Attribute.Name = KeyAttributeName
				And AttributeStructure.ValueType.ContainsType(StringType);
			
			ObjectStructure.Insert(Attribute.Name, AttributeStructure);
			
		EndDo;
	EndIf;
	
	For Each Attribute In ObjectMetadata.Attributes Do
		
		AttributeNameWithoutDigit = Left(Attribute.Name, StrLen(Attribute.Name) - 1);
		If StrEndsWith(AttributeNameWithoutDigit, "Language") Then
			Continue;
		EndIf;
		
		AttributeStructure = InitializeAttributeStructure();
		AttributeStructure.ValueType      = Attribute.Type;
		AttributeStructure.IsExcludable      = AttributeIsExcluded(Attribute, ObjectMetadata);
		AttributeStructure.ToLocalize     = AttributesToLocalize.Property(Attribute.Name);
		AttributeStructure.AttributeString        = AttributeStructure.ValueType.ContainsType(StringType);
		
		ObjectStructure.Insert(Attribute.Name, AttributeStructure);
		
	EndDo;
	
	If Not TabularSection Then
		
		For Each ObjectTSMetadata In ObjectMetadata.TabularSections Do
			
			ObjectTSAttributes1 = GetMetadataObjectAttributes(ObjectTSMetadata, KeyAttributeName, True);
			
			AttributeStructure = InitializeAttributeStructure();
			AttributeStructure.Attributes = ObjectTSAttributes1;
			AttributeStructure.IsExcludable = TableIsExcluded(ObjectTSAttributes1, ObjectTSMetadata);
			
			If ObjectTSAttributes1.Count() > 2
				Or Not (ObjectTSAttributes1.Count() = 1 And ObjectTSAttributes1.Property(KeyAttributeName)) Then
				ObjectStructure.Insert(ObjectTSMetadata.Name, AttributeStructure);
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Return SortedObjectStructure(ObjectStructure, KeyAttributeName);
	
EndFunction

Function AttributeIsExcluded(Attribute, ObjectMetadata)
	
	Return AttributeIsExcludedByName(Attribute.Name, ObjectMetadata.FullName())
			Or AttributeIsExcludedByType(Attribute.Type)
			Or IsObsoleteItem(Attribute.Name);
	
EndFunction

Function TableIsExcluded(Attributes, ObjectMetadata)
	
	IsExcludable = IsObsoleteItem(ObjectMetadata.Name) Or Attributes.Count() = 0;
	HasAttributesNotToExclude = False;
	
	For Each Attribute In Attributes Do
		If IsExcludable Then
			Attribute.Value.IsExcludable = True;
		Else
			HasAttributesNotToExclude = HasAttributesNotToExclude Or Not Attribute.Value.IsExcludable;
		EndIf;
	EndDo;
	
	IsExcludable = IsExcludable Or Not HasAttributesNotToExclude;
	
	Return IsExcludable;
	
EndFunction

Function IsObsoleteItem(TagName)
	Return StrStartsWith(Upper(TagName), "DELETE");
EndFunction

Function AttributeIsExcludedByName(AttributeName, ObjectName)
	
	Return AttributeName = "ActionPeriodIsBasic" And StrStartsWith(ObjectName, "ChartOfCalculationTypes");
	
EndFunction

Function AttributeIsExcludedByType(AttributeType)
	
	StorageTypesDetails = New TypeDescription("ValueStorage");
	UUIDTypesDetails = New TypeDescription("UUID");
	TypesDetailsTypesDetails = New TypeDescription("TypeDescription");
	AccountKindTypesDetails = New TypeDescription("AccountType");
	
	If AttributeType = Undefined Then
		Return True;
	ElsIf AttributeType = Type("ValueStorage") Or AttributeType = StorageTypesDetails Then
		Return True;
	ElsIf AttributeType = Type("UUID") Or AttributeType = UUIDTypesDetails Then
		Return True;
	ElsIf AttributeType = Type("TypeDescription") Or AttributeType = TypesDetailsTypesDetails Then
		Return False;
	ElsIf AttributeType = Type("AccountType") Or AttributeType = AccountKindTypesDetails Then
		Return False;
	EndIf;
	
	TypesDetailsString = New TypeDescription("String");
	TypesDetailsBoolean = New TypeDescription("Boolean");
	TypesDetailsDate = New TypeDescription("Date");
	TypesDetailsNumber = New TypeDescription("Number");
	
	Basic = True;
	For Each Type In AttributeType.Types() Do
		Basic = Basic And (TypesDetailsString.ContainsType(Type)
								Or TypesDetailsBoolean.ContainsType(Type)
								Or TypesDetailsDate.ContainsType(Type)
								Or TypesDetailsNumber.ContainsType(Type));
	EndDo;
	
	If Basic Then
		Return False;
	EndIf;
	
	// This is a composite attribute.
	If AttributeType.Types().Count() > 1 Then
		Return True;
	EndIf;
	
	AttributeByType = AttributeType.AdjustValue();
	
	If BusinessProcesses.RoutePointsAllRefsType().ContainsType(TypeOf(AttributeByType)) Then
		Return True;
	EndIf;
	
	MetadataByType = AttributeByType.Metadata();
	MetadataByTypeSection = StrReplace(MetadataByType.FullName(), "."+MetadataByType.Name, "");
	
	If StrFind("ExchangePlan, Catalog, ChartOfCharacteristicTypes, ChartOfAccounts, ChartOfCalculationTypes, Enum", MetadataByTypeSection) > 0 Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

Function InitializeAttributeStructure()
	
	Return New Structure("ValueType, IsExcludable, Attributes, ToLocalize, AttributeString");

EndFunction

Function SortedObjectStructure(ObjectStructure, KeyAttributeName)
	
	StructureTable = New ValueTable;
	StructureTable.Columns.Add("AttributeName");
	StructureTable.Columns.Add("AttributeStructure");
	StructureTable.Columns.Add("Order");
	
	For Each KeyAndValue In ObjectStructure Do
		TableRow = StructureTable.Add();
		TableRow.AttributeName = KeyAndValue.Key;
		TableRow.AttributeStructure = KeyAndValue.Value;
		
		If KeyAndValue.Key = "PredefinedDataName" Then
			TableRow.Order = 0;
		ElsIf KeyAndValue.Key = KeyAttributeName Then
			TableRow.Order = 1;
		Else
			TableRow.Order = 2;
		EndIf;
	EndDo;
	
	StructureTable.Sort("AttributeName");
	StructureTable.Sort("Order");
	
	ResultingStructure = New Structure;
	
	For Each TableRow In StructureTable Do
		ResultingStructure.Insert(TableRow.AttributeName, TableRow.AttributeStructure);
	EndDo;
	
	Return ResultingStructure;
	
EndFunction

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.';
						|en = 'Invalid object call on the client.';");
#EndIf
