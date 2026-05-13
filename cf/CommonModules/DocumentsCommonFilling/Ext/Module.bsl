
Procedure FillDocumentCompanyFilling(Source, FillingData, FillingText, StandardProcessing) Export
	
	MetadataObject = Source.Metadata();
	If MetadataObject.Attributes.Find("Company") = Undefined Then
		Return;
	EndIf;
	
	Source.Company = Constants.DefaultCompany.Get();
	
EndProcedure

