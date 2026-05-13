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

#Region Public

// Returns catalog's key attributes.
// 
// Returns:
//   - Map 
//
Function KeyAttributes() Export

	KeyAttributes = New Map;
	KeyAttributes.Insert("Products");
	KeyAttributes.Insert("StorageLocation");
	Return KeyAttributes;

EndFunction

// Runs when replacing duplicates in the item attributes.
//
// Parameters:
//  ReplacementPairs - Map - Contains the original—duplicate value pairs.
//  UnprocessedOriginalsValues - Array of Structure:
//    * ValueToReplace - AnyRef - The original value of a replaceable object.
//    * UsedLinks - See Common.SubordinateObjectsLinksByTypes
//    * KeyAttributesValue - Structure - Key is the attribute name. Value is the attribute value.
//
Procedure OnSearchForReferenceReplacement(ReplacementPairs, UnprocessedOriginalsValues) Export

	For Each UnprocessedDuplicate In UnprocessedOriginalsValues Do
		Manager = Common.ObjectManagerByRef(UnprocessedDuplicate.ValueToReplace);
		
		ParametersOfKey = New Structure;
		For Each KeyAttribute In UnprocessedDuplicate.KeyAttributesValue Do
			ValueOfOriginal = ReplacementPairs.Get(KeyAttribute.Value);
			ParametersOfKey.Insert(KeyAttribute.Key, ?(ValueOfOriginal = Undefined, KeyAttribute.Value, ValueOfOriginal));
		EndDo;
	
		ReplacementPairs.Insert(UnprocessedDuplicate.ValueToReplace, Manager.CreateKey(ParametersOfKey));
	EndDo;

EndProcedure

// Creates a new key by the key fields, or returns the existing one.
//
// Parameters:
//  ParametersOfKey - Structure:
//   * StorageLocation - CatalogRef._DemoPartners, CatalogRef._DemoStorageLocations
//   * Products - CatalogRef._DemoProducts
//
// Returns:
//   CatalogRef._DemoProductDimensionKeys 
//
Function CreateKey(ParametersOfKey) Export

	SetPrivilegedMode(True);

	Query = New Query;
	Query.Text =
	"SELECT
	|	_DemoProductDimensionKeys.Ref AS Ref
	|FROM
	|	Catalog._DemoProductDimensionKeys AS _DemoProductDimensionKeys
	|WHERE
	|	_DemoProductDimensionKeys.Products = &Products
	|	AND _DemoProductDimensionKeys.StorageLocation = &StorageLocation";

	Query.SetParameter("StorageLocation", ParametersOfKey.StorageLocation);
	Query.SetParameter("Products", ParametersOfKey.Products);

	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Var_Key = Catalogs._DemoProductDimensionKeys.CreateItem();
		Var_Key.Description = String(ParametersOfKey.Products) + "," + String(ParametersOfKey.StorageLocation);
		Var_Key.Products = ParametersOfKey.Products;
		Var_Key.StorageLocation = ParametersOfKey.StorageLocation;
		Var_Key.Write();
	Else
		Var_Key = QueryResult.Select();
		Var_Key.Next();
	EndIf;

	Return Var_Key.Ref;

EndFunction

#EndRegion

#EndIf