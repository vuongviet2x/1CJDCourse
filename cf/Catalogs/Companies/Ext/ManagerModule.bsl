
Function CompanyLogo(Company) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Companies.LogoPicture AS LogoPicture
	|FROM
	|	Catalog.Companies AS Companies
	|WHERE
	|	Companies.Ref = &Ref";
	
	Query.SetParameter("Ref", Company);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.LogoPicture.Get();
	Else
		Return Undefined;
	EndIf;
	
EndFunction

