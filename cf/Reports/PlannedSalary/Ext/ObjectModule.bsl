
Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)

	StandardProcessing = False;
	
	CompositionSettings = SettingsComposer.GetSettings();

	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(
		DataCompositionSchema,
		CompositionSettings,
		DetailsData
	);
	
	ExternalDataSets = New Structure;
	ExternalDataSets.Insert("PayrollAccrualsFromHRM", PayrollAccrualsFromHRM());
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, ExternalDataSets, DetailsData, True);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	
	OutputProcessor.Output(CompositionProcessor);
	
EndProcedure

Function PayrollAccrualsFromHRM()

	Result = New ValueTable;
	Result.Columns.Add("Employee", New TypeDescription("CatalogRef.Employees"));
	Result.Columns.Add("Company", New TypeDescription("CatalogRef.Companies"));
	
	NumberQualifier = New NumberQualifiers(10, 0, AllowedSign.Nonnegative);
	Result.Columns.Add("NumberOfHours", New TypeDescription("Number", NumberQualifier));
	Result.Columns.Add("CurrentSalary", New TypeDescription("Number", NumberQualifier));
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	EmployeesSliceLast.Employee AS Employee,
	|	EmployeesSliceLast.Company AS Company
	|FROM
	|	InformationRegister.Employees.SliceLast(&CurrentDate, ) AS EmployeesSliceLast
	|WHERE
	|	EmployeesSliceLast.Works";

	CurrentDate = CurrentSessionDate();

	Query.SetParameter("CurrentDate", CurrentDate);
	Selection = Query.Execute().Select();

	// Number of days during this month up to the current date multiple 8 hours per day
	NumberOfHoursCurrentMonth = Day(CurrentDate) * 8;
	
	RandomNumberGenerator = New RandomNumberGenerator;
	While Selection.Next() Do
		
		NewRow = Result.Add();
		
		FillPropertyValues(NewRow, Selection);
		NewRow.NumberOfHours = RandomNumberGenerator.RandomNumber(1, NumberOfHoursCurrentMonth);
		NewRow.CurrentSalary = NewRow.NumberOfHours * 500;
		
	EndDo;
	
	Return Result;

EndFunction

