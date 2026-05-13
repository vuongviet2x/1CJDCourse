
Function DefaultCompany() Export

	Query = New Query;
	Query.Text = 
	"SELECT TOP 2
	|	Companies.Ref AS Company
	|FROM
	|	Catalog.Companies AS Companies
	|WHERE
	|	NOT Companies.DeletionMark";
	
	Selection = Query.Execute().Select();
	If Selection.Count() = 1 Then
		Selection.Next();
		Return Selection.Company;
	Else
		Return Catalogs.Companies.EmptyRef();
	EndIf;
	
EndFunction
