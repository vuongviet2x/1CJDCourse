
#Region Internal

// Returns a table of external links for the given forms.
//
// Parameters:
//	HashPathToForm - String - Hash the full path to a form.
//
// Returns:
//	ValueTable - Table of information references for the form with the following columns:
//	* Description - String - External link name.
//	* Address - String - External link address.
//	* Weight - Number - External link weight.
//	* RelevantFrom - Date - Start date of the external link lifetime.
//	* RelevantTo - Date - End date of the external link lifetime.
//	* ToolTip - String - External link tooltip.
//
Function InformationReferences(HashPathToForm) Export
	
	Query = New Query;
	Query.SetParameter("Hash", HashPathToForm);
	Query.SetParameter("CurrentDate", CurrentSessionDate());
	Query.Text = 
	"SELECT
	|	FullPathsToForms.Ref AS Ref
	|INTO PathsToForms
	|FROM
	|	Catalog.FullPathsToForms AS FullPathsToForms
	|WHERE
	|	FullPathsToForms.Hash = &Hash
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InformationReferencesForForms.Description AS Description,
	|	InformationReferencesForForms.Address AS Address,
	|	InformationReferencesForForms.Weight AS Weight,
	|	InformationReferencesForForms.RelevantFrom AS RelevantFrom,
	|	InformationReferencesForForms.RelevantTo AS RelevantTo,
	|	InformationReferencesForForms.ToolTip AS ToolTip
	|FROM
	|	PathsToForms AS PathsToForms
	|		INNER JOIN Catalog.InformationReferencesForForms AS InformationReferencesForForms
	|		ON PathsToForms.Ref = InformationReferencesForForms.FullFormPath
	|WHERE
	|	InformationReferencesForForms.RelevantFrom <= &CurrentDate
	|	AND InformationReferencesForForms.RelevantTo >= &CurrentDate
	|
	|ORDER BY
	|	Weight DESC";
	
	Return Query.Execute().Unload();
	
EndFunction

#EndRegion