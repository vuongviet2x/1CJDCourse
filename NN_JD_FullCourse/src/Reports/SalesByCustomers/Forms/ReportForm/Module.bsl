
&AtServer
Procedure GenerateAtServer()
	
	Result.Clear();
	
	Template = Reports.SalesByCustomers.GetTemplate("Sales");
	
	AreaTitle 			= Template.GetArea("Title");
	AreaHeaderProducts 	= Template.GetArea("HeaderProducts");
	AreaRowCompany  	= Template.GetArea("RowCompany");
	AreaRowCustomer 	= Template.GetArea("RowCustomer");
	AreaRowProduct  	= Template.GetArea("RowProduct");
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	SalesTurnovers.Product AS Product,
	|	SalesTurnovers.Company AS Company,
	|	SalesTurnovers.Customer AS Customer,
	|	SalesTurnovers.QuantityTurnover AS Quantity,
	|	SalesTurnovers.AmountTurnover AS Amount
	|FROM
	|	AccumulationRegister.Sales.Turnovers(
	|			&BeginDate,
	|			&EndDate,
	|			,
	|			CASE
	|					WHEN &FilterCompanies
	|						THEN Company IN(&Companies)
	|					ELSE TRUE
	|				END
	|				AND CASE
	|					WHEN &FilterCustomers
	|						THEN Customer IN(&Customers)
	|					ELSE TRUE
	|				END
	|				AND CASE
	|					WHEN &FilterProducts
	|						THEN Product IN(&Products)
	|					ELSE TRUE
	|				END) AS SalesTurnovers
	|
	|ORDER BY
	|	SalesTurnovers.Company.Description,
	|	SalesTurnovers.Customer.Description,
	|	SalesTurnovers.Product.Description
	|TOTALS
	|	SUM(Quantity),
	|	SUM(Amount)
	|BY
	|	Company,
	|	Customer";
	
	BeginDate = Period.StartDate;
	If ValueIsFilled(Period.EndDate) Then
		EndDate = EndOfDay(Period.EndDate);
	Else	
		EndDate = Undefined;
	EndIf;
	
	Query.SetParameter("BeginDate", 		BeginDate);
	Query.SetParameter("EndDate", 			EndDate);
	Query.SetParameter("FilterCompanies", 	ValueIsFilled(Companies));
	Query.SetParameter("Companies", 		Companies);
	Query.SetParameter("FilterCustomers", 	ValueIsFilled(Customers));
	Query.SetParameter("Customers", 		Customers);
	Query.SetParameter("FilterProducts", 	ValueIsFilled(Products));
	Query.SetParameter("Products", 			Products);
	
	QueryResult = Query.Execute();
	
	FormattedBeginDate = Format(BeginDate, "DLF=D");
	FormattedEndDate   = Format(EndDate, "DLF=D");
	If ValueIsFilled(BeginDate) And ValueIsFilled(EndDate) Then
		ReportTitle = StrTemplate("Sales by customers from %1 to %2", FormattedBeginDate, FormattedEndDate);
	ElsIf ValueIsFilled(BeginDate) Then
		ReportTitle = StrTemplate("Sales by customers from %1", FormattedBeginDate);
	ElsIf ValueIsFilled(EndDate) Then
		ReportTitle = StrTemplate("Sales by customers before %1", FormattedEndDate);
	Else
		ReportTitle = "Sales by customers";
	EndIf;
		
	AreaTitle.Parameters.Title = ReportTitle;
	Result.Put(AreaTitle);
	
	Result.Put(AreaHeaderProducts);
	
	Result.StartRowAutoGrouping();
	
	SelectionCompanies = QueryResult.Select(QueryResultIteration.ByGroups);
	LineNumber = 1;
	While SelectionCompanies.Next() Do
		
		AreaRowCompany.Parameters.Fill(SelectionCompanies);
		AreaRowCompany.Parameters.LineNumber = Format(LineNumber, "NG=");
		Result.Put(AreaRowCompany, SelectionCompanies.Level());
		
		SelectionCustomers = SelectionCompanies.Select(QueryResultIteration.ByGroups);
		LineNumberCustomers = 1;
		While SelectionCustomers.Next() Do
			AreaRowCustomer.Parameters.Fill(SelectionCustomers);
			AreaRowCustomer.Parameters.LineNumber = StrTemplate(
				"%1.%2",
				Format(LineNumber, "NG="),
				Format(LineNumberCustomers, "NG=")
			);
			Result.Put(AreaRowCustomer, SelectionCustomers.Level());
			
			SelectionProducts = SelectionCustomers.Select();
			LineNumberProducts = 1;
			While SelectionProducts.Next() Do
				AreaRowProduct.Parameters.Fill(SelectionProducts);
				AreaRowProduct.Parameters.LineNumber = StrTemplate(
					"%1.%2.%3",
					Format(LineNumber, "NG="),
					Format(LineNumberCustomers, "NG="),
					Format(LineNumberProducts, "NG=")
				);
				Result.Put(AreaRowProduct, SelectionProducts.Level());
			
				LineNumberProducts = LineNumberProducts + 1;
			EndDo;			
			
			LineNumberCustomers = LineNumberCustomers + 1;
		EndDo;	
		
		LineNumber = LineNumber + 1;
	EndDo;
	
	Result.EndRowAutoGrouping();
	
EndProcedure

&AtClient
Procedure Generate(Command)
	GenerateAtServer();
EndProcedure
