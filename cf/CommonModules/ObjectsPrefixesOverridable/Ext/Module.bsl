///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Public

// Event handler on the object number change.
// The handler is intended to compute a basic object number
// when it cannot be got in a standard way without information loss.
// The handler is called only if processed object numbers and codes
// were generated in a non-standard way, i.e. not in the SSL number and code format.
//
// Parameters:
//  Object - DocumentObject
//         - BusinessProcessObject
//         - TaskObject - a data object
//           whose basic number is to be defined.
//  Number - String - a number of the current object a basic number is to be got from.
//  BasicNumber - String - a basic object number. 
//           It is an object number
//           without any prefixes (infobase prefix, company prefix,
//           department prefix, custom prefix, and other prefixes).
//  StandardProcessing - Boolean - a standard processing flag. Default value is True.
//           If the parameter in the handler is set to False,
//           the standard processing will not be performed.
//           The standard processing gets a basic code to the right of the first non-numeric character.
//           For example, for code AA00005/12/368, the standard processing returns 368.
//           However, the basic object code is equal to 5/12/368.
//
Procedure OnChangeNumber(Object, Val Number, BasicNumber, StandardProcessing) Export
	
	// _Demo Example Start
	If TypeOf(Object) = Type("DocumentObject._DemoGoodsSales") Then
		
		If Mid(Number, 5, 1) <> "-" Then
			
			// The document number's format is obsolete: "ABCD0012345".
			// Override the standard number processing.
			StandardProcessing = False;
			
			// Getting a previous infobase prefix from the infobase.
			PreviousIBPrefix = "A";
			
			// Getting a previous company prefix from the infobase.
			PreviousCompanyPrefix = "B";
			
			// Getting a previous department prefix from the infobase.
			PreviousDepartmentPrefix = "In";
			
			// Getting a custom prefix from the document.
			Prepayment_ = StrFind(Lower(Object.Comment), "prepayment_") > 0;
			
			CustomPrefix = ?(Prepayment_, "G", "");
			
			BasicNumber = Mid(Number,
				  StrLen(PreviousIBPrefix)
				+ StrLen(PreviousCompanyPrefix)
				+ StrLen(PreviousDepartmentPrefix)
				+ StrLen(CustomPrefix)
				+ 1);
			
		EndIf;
		
	EndIf;
	// _Demo Example End
	
EndProcedure

// Event handler on the object code change.
// The handler is intended to compute a basic object code
// when it cannot be got in a standard way without information loss.
// The handler is called only if processed object numbers and codes
// were generated in a non-standard way, i.e. not in the SSL number and code format.
//
// Parameters:
//  Object - CatalogObject
//         - ChartOfCharacteristicTypesObject - a data object
//           whose basic code is to be defined.
//  Code - String - a code of the current object from which a basic code is to be got.
//  BasicCode - String - a basic object code. It is an object code
//           without any prefixes (infobase prefix, company prefix,
//           department prefix, custom prefix, and other prefixes).
//  StandardProcessing - Boolean - a standard processing flag. Default value is True.
//           If the parameter in the handler is set to False,
//           the standard processing will not be performed.
//           The standard processing gets a basic code to the right of the first non-numeric character.
//           For example, for code AA00005/12/368, the standard processing returns 368.
//           However, the basic object code is equal to 5/12/368.
//
Procedure OnChangeCode(Object, Val Code, BasicCode, StandardProcessing) Export
	
EndProcedure

// For each metadata object where the attribute
// that stores a company reference has a custom name (not Company), fill in the Objects parameter in this procedure.
//
// Parameters:
//  Objects - ValueTable:
//     * Object - MetadataObject - a metadata object, for which an attribute
//                containing a reference to a company is specified.
//     * Attribute - String - a name of the attribute that stores a company reference.
//
Procedure GetPrefixGeneratingAttributes(Objects) Export
	
	// _Demo Example Start
	TableRow = Objects.Add();
	TableRow.Object = Metadata.Documents._DemoGoodsSales;
	TableRow.Attribute = "ParentCompany";
	// _Demo Example End
	
EndProcedure

#EndRegion
