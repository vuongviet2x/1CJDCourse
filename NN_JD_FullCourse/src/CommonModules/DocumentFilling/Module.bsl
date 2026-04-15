
Procedure SetNewNumber(StandardProcessing, Prefix, Company) Export
	
	Prefix = GetFunctionalOption("CompanyPrefix", New Structure("Company", Company));

EndProcedure

Procedure FillCompanyInDocumentsFilling(Source, FillingData, FillingText, StandardProcessing) Export
	
	MetadataObject = Source.Metadata();
	If MetadataObject.Attributes.Find("Company") = Undefined Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(Source.Company) Then
		Source.Company = Catalogs.Companies.DefaultCompany();
	EndIf;
	
EndProcedure
