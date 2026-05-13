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

// Defines print form templates that support multiple languages.
// 
// Parameters:
//  Templates - Array of MetadataObjectTemplate
//
Procedure WhenDefiningAvailableForTranslationLayouts(Templates) Export
	
	// _Demo Example Start
	Templates.Add(Metadata.Documents._DemoCustomerProformaInvoice.Templates.PF_MXL_OrderInvoice);
	// _Demo Example End
	
EndProcedure

#EndRegion
