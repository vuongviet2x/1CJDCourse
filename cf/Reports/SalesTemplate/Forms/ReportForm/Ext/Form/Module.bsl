
&AtServer
Procedure GenerateAtServer()
	
	Result.Clear();
	
	Template = Reports.SalesTemplate.GetTemplate("Sales"); 
	
	AreaTitle 			= Template.GetArea("Title");
	AreaHeaderProducts 	= Template.GetArea("HeaderProducts");
	AreaRowCustomer 	= Template.GetArea("RowCustomer");
	AreaRowProduct 		= Template.GetArea("RowProduct");
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	SalesTurnovers.Product AS Product,
	|	SalesTurnovers.Customer AS Customer,
	|	SalesTurnovers.AmountTurnover AS Amount
	|FROM
	|	AccumulationRegister.Sales.Turnovers(
	|			&BeginDate,
	|			&EndDate,
	|			,
	|			CASE
	|				WHEN &FilterProducts
	|					THEN Product IN (&Products)
	|				ELSE TRUE
	|			END) AS SalesTurnovers
	|TOTALS
	|	SUM(Amount)
	|BY
	|	Customer";
	
	BeginDate = Period.StartDate;
	If ValueIsFilled(Period.EndDate) Then
		EndDate = EndOfDay(Period.EndDate);
	Else
		EndDate = Undefined;
	EndIf;
	
	Query.SetParameter("BeginDate", 	 BeginDate);
	Query.SetParameter("EndDate", 		 EndDate);
	Query.SetParameter("Products", 		 Products);
	Query.SetParameter("FilterProducts", ValueIsFilled(Products));
	
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
	
	If QueryResult.IsEmpty() Then
		Return;	
	EndIf;
	
	Result.StartRowAutoGrouping();
	
	SelectionCustomers = QueryResult.Select(QueryResultIteration.ByGroups);

	LineNumber = 1;
	While SelectionCustomers.Next() Do
		AreaRowCustomer.Parameters.Fill(SelectionCustomers);
		AreaRowCustomer.Parameters.LineNumber = Format(LineNumber, "NG=");
		
		Result.Put(AreaRowCustomer, SelectionCustomers.Level());
		
		SelectionProducts = SelectionCustomers.Select();
		
		LineNumberProducts = 1;
		While SelectionProducts.Next() Do
			AreaRowProduct.Parameters.Fill(SelectionProducts);
			AreaRowProduct.Parameters.LineNumber = StrTemplate(
				"%1.%2",
				Format(LineNumber, "NG="),
				Format(LineNumberProducts, "NG=")
			);

			Result.Put(AreaRowProduct, SelectionProducts.Level());
			
			LineNumberProducts = LineNumberProducts + 1;
		EndDo;
		
		LineNumber = LineNumber + 1;
	EndDo;
	
	Result.EndRowAutoGrouping();
	
EndProcedure

&AtClient
Procedure Generate(Command)
	GenerateAtServer();
EndProcedure
