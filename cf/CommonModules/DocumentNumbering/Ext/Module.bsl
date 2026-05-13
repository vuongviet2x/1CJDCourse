
Procedure SetNewNumber(StandardProcessing, Prefix, Company) Export
	
	Prefix = GetFunctionalOption("CompanyPrefix", New Structure("Company", Company));

EndProcedure
