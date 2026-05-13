
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetFunctionalOptionParameters();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	ChangeDeliveryAttributesPresentation();
EndProcedure

&AtClient
Procedure BeforeCloseAnswer(Result, AdditionalParameters) Export

	If Result = DialogReturnCode.Yes Then
		CloseWithoutChecking = True;
		Close();
	EndIf;

EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	NotCheckedAttributes = New Array;
	
	If Not Object.DeliveryIsRequired Then
		NotCheckedAttributes.Add("City");
		NotCheckedAttributes.Add("District");
		NotCheckedAttributes.Add("Street");
		NotCheckedAttributes.Add("Building");
		NotCheckedAttributes.Add("Apartment");
	EndIf;
	
	For Each AttributeName In NotCheckedAttributes Do
		ElementIndex = CheckedAttributes.Find(AttributeName);
		If ElementIndex <> Undefined Then
			CheckedAttributes.Delete(ElementIndex);
		EndIf;
	EndDo;
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	//CurrentWorkplace = CommonClient.CurrentWorkplace();
	//WriteParameters.Insert("Workplace", CurrentWorkplace);
	WriteParameters.Insert("NewObject", Object.Ref.IsEmpty());
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// This code doesn't change the object of document,
	// because the object is already placed in the CurrentObject parameter
	Object.Date = EndOfDay(Object.Date);
	
	// That's why we should work with CurrentObject to change the object
	CurrentObject.Date = EndOfDay(CurrentObject.Date);
	
	If WriteParameters.Property("Workplace") Then
	
		Workplace = WriteParameters.Workplace;
		//WorkplaceParameters = ParametersOfWorkplace(Workplace);
		//
		//If WorkplaceParameters.RecalculateDiscountsOnWrite Then
		//	CalculateDiscounts();
		//EndIf;
	EndIf;
	
	FillDeliveryAddress();
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// SaveAddressParts();
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	// Notification for other forms
	Notify("Write_SalesInvoice", WriteParameters, Object.Ref);
	
	If WriteParameters.Property("NewObject") And WriteParameters.NewObject Then
		TitleText = "Created:";
	Else
		TitleText = "Edited:";	
	EndIf;
	
	URL = GetURL(Object.Ref);
	MessageText = String(Object.Ref);
	
	// Notification for a user
	ShowUserNotification(TitleText, URL, MessageText, PictureLib.Information);

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	FillInSoldThisMonth();
	
EndProcedure

&AtServer
Procedure FillInSoldThisMonth()

	ProductsForTurnovers = Object.Products.Unload().UnloadColumn("Product");
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	SalesTurnovers.Product AS Product,
	|	SalesTurnovers.AmountTurnover AS Amount
	|FROM
	|	AccumulationRegister.Sales.Turnovers(&BeginOfMonth,
	|											&EndOfDay,
	|											Period,
	|											Product IN (&Products)) AS SalesTurnovers";
	
	Query.SetParameter("BeginOfMonth", 	BegOfMonth(Object.Date));
	Query.SetParameter("EndOfDay", 		EndOfDay(Object.Date));
	Query.SetParameter("Products", 		ProductsForTurnovers);
	
	SelectionAmount = Query.Execute().Select();
	
	SearchFilter = New Structure("Product");
	While SelectionAmount.Next() Do
		
		SearchFilter.Product = SelectionAmount.Product;
		
		FoundRows = Object.Products.FindRows(SearchFilter);
		For Each ProductsRow In FoundRows Do
		
			ProductsRow.SoldThisMonth = SelectionAmount.Amount; 
		
		EndDo;
		
	EndDo;

EndProcedure

&AtServer
Procedure SaveAddressParts()

	// City
	Query = New Query;
	Query.Text = 
	"SELECT
	|	Cities.Ref AS Ref
	|FROM
	|	Catalog.Cities AS Cities
	|WHERE
	|	Cities.Description = &City";

	Query.SetParameter("City", City);
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		NewCity = Catalogs.Cities.CreateItem();
		
		NewCity.Description = City;
		
		NewCity.Write();
	EndIf;
	
	// District
	// ...
	
EndProcedure

&AtClient
Procedure CompanyOnChange(Item)
	
	OnCompanyChangeAtServer();
	
EndProcedure

&AtServer
Procedure OnCompanyChangeAtServer()

	SetFunctionalOptionParameters();

EndProcedure

&AtClient
Procedure CustomerOnChange(Item)
	
	FillMainContractAtServer();

EndProcedure

&AtServer
Procedure FillMainContractAtServer()

	DocumentObject = FormAttributeToValue("Object");
	DocumentObject.FillMainContract();
	
	ValueToFormAttribute(DocumentObject, "Object");

EndProcedure

&AtClient
Procedure ProductsQuantityOnChange(Item)

	CurrentData = Items.Products.CurrentData;
	If CurrentData <> Undefined Then
		FillAmountInCurrentData(CurrentData);
	EndIf;
	
	OnProductOrQuantityChangeAtServer();
	
EndProcedure

&AtClient
Procedure FillAmountInCurrentData(CurrentData)
	
	CurrentData.Amount = CurrentData.Price * CurrentData.Quantity;
	
EndProcedure

&AtClient
Procedure ProductsProductOnChange(Item)
		
	OnProductOrQuantityChangeAtServer();
	
EndProcedure

&AtClient
Procedure ProductsServicesPriceOnChange(Item)
	
	CurrentData = Item.Parent.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	FillAmountInCurrentData(CurrentData);
	
EndProcedure

&AtServer
Procedure OnProductOrQuantityChangeAtServer()

	CalculateWeightAtServer();
		
EndProcedure

&AtServer
Procedure CalculateWeightAtServer()

	TotalWeight = 0;
	For Each ProductsRow In Object.Products Do
	
		TotalWeight = TotalWeight + WeightOfProduct(ProductsRow.Product) * ProductsRow.Quantity;
	
	EndDo;

EndProcedure

&AtServerNoContext
Function WeightOfProduct(Product)

	Return Product.Weight;

EndFunction

&AtClient
Procedure PickProducts(Command)
	PickProductsToTable(Items.Products, PredefinedValue("Enum.ProductTypes.Product"));
EndProcedure

&AtClient
Procedure PickServices(Command)
	PickProductsToTable(Items.Services, PredefinedValue("Enum.ProductTypes.Service"));
EndProcedure

&AtClient
Procedure PickProductsToTable(TableItem, ProductType)

	OpenForm(
		"Catalog.Products.ChoiceForm",
		New Structure("MultipleChoice, CloseOnChoise, Filter", False, False, New Structure("Type", ProductType)),
		TableItem
	);

EndProcedure

&AtClient
Procedure ProductsChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	FoundRows = Object.Products.FindRows(New Structure("Product", SelectedValue));
	If FoundRows.Count() = 0 Then
		NewRow = Object.Products.Add();
		NewRow.Product = SelectedValue;
		NewRow.Quantity = 1;
	EndIf;
	
EndProcedure

&AtClient
Procedure ServicesChoiceProcessing(Item, SelectedValue, StandardProcessing)
	
	FoundRows = Object.Services.FindRows(New Structure("Product", SelectedValue));
	If FoundRows.Count() = 0 Then
		NewRow = Object.Services.Add();
		NewRow.Product = SelectedValue;
		NewRow.Quantity = 1;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetFunctionalOptionParameters()
	
	FunctionalOptionParatemets = New Structure("Company", Object.Company);
	
	SetFormFunctionalOptionParameters(FunctionalOptionParatemets);
	
EndProcedure

&AtServer
Procedure FillDeliveryAddress()
	
	AddressParts = New Array;
	AddressParts.Add(City);
	AddressParts.Add(District);
	AddressParts.Add(Street);
	AddressParts.Add(Building);
	AddressParts.Add(Apartment);

	// StrConcat function merges an array of strings passed (the first parameter) 
	// into a single string with the specified separator (the second parameter) 
	Object.DeliveryAddress = StrConcat(AddressParts, ", ");
	
EndProcedure

&AtClient
Procedure DeliveryIsRequiredOnChange(Item)
	ChangeDeliveryAttributesPresentation();
EndProcedure

&AtClient
Procedure ChangeDeliveryAttributesPresentation()

	Items.GroupDelivery.ReadOnly = Not Object.DeliveryIsRequired;

EndProcedure
